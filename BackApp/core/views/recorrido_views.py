from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from django.shortcuts import get_object_or_404

from core.models import Recorrido, SolicitudDeViaje
from core.serializers import RecorridoSerializer, PasajeroAceptadoSerializer, RecorridoDetalleSerializer
from core.utils.precios import calcular_precio_por_pasajero
from core.utils.geo import geocodificar_direccion, calcular_distancia_km, obtener_ruta


class RecorridoView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        recorridos = Recorrido.objects.all().order_by('-fecha_hora_salida')
        serializer = RecorridoSerializer(recorridos, many=True)
        return Response(serializer.data)

    def post(self, request):
        if not request.user.es_conductor:
            return Response({'detalle': 'Solo los conductores pueden crear recorridos.'}, status=403)

        data = request.data.copy()

        try:
            origen_coords = (float(data.get('origen_lat')), float(data.get('origen_lon')))
            destino_coords = (float(data.get('destino_lat')), float(data.get('destino_lon')))
            distancia = calcular_distancia_km(origen_coords, destino_coords)
            data['distancia_km'] = distancia
        except Exception as e:
            print("❌ Error al calcular distancia:", e)
            return Response({'detalle': 'Error en los datos de coordenadas para calcular la distancia.'}, status=400)

        serializer = RecorridoSerializer(data=data)
        if serializer.is_valid():
            recorrido = serializer.save(conductor=request.user)
            return Response(RecorridoSerializer(recorrido).data, status=201)
        return Response(serializer.errors, status=400)


class PrecioPorPasajeroView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, recorrido_id):
        recorrido = get_object_or_404(Recorrido, pk=recorrido_id)
        precio = calcular_precio_por_pasajero(recorrido)
        return Response({'precio_por_pasajero': precio})


class PasajerosAceptadosView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, recorrido_id):
        recorrido = get_object_or_404(Recorrido, pk=recorrido_id)

        if recorrido.conductor != request.user:
            return Response({'detalle': 'No tienes permiso para ver esta información.'}, status=403)

        solicitudes = SolicitudDeViaje.objects.filter(
            recorrido=recorrido, estado='aceptada'
        )
        serializer = PasajeroAceptadoSerializer(solicitudes, many=True)
        return Response(serializer.data)


class CambiarEstadoRecorridoView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, recorrido_id, nuevo_estado):
        recorrido = get_object_or_404(Recorrido, pk=recorrido_id)

        if recorrido.conductor != request.user:
            return Response({'detalle': 'No tienes permiso para modificar este recorrido.'}, status=403)

        if nuevo_estado not in ['en_curso', 'completado', 'cancelado']:
            return Response({'detalle': 'Estado inválido.'}, status=400)

        recorrido.estado = nuevo_estado
        recorrido.save()

        return Response({'mensaje': f'Recorrido marcado como "{nuevo_estado}".'})


class RecorridoMapaView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, recorrido_id):
        recorrido = get_object_or_404(Recorrido, pk=recorrido_id)

        if request.user != recorrido.conductor and not SolicitudDeViaje.objects.filter(recorrido=recorrido, pasajero=request.user).exists():
            return Response({'detalle': 'No tienes permiso para ver este mapa.'}, status=403)

        pasajeros = SolicitudDeViaje.objects.filter(recorrido=recorrido, estado='aceptada')

        data = {
            "recorrido": {
                "origen": recorrido.origen,
                "lat_origen": recorrido.origen_lat,
                "lon_origen": recorrido.origen_lon,
                "destino": recorrido.destino,
                "lat_destino": recorrido.destino_lat,
                "lon_destino": recorrido.destino_lon,
            },
            "pasajeros": [
                {
                    "nombres": p.pasajero.nombres,
                    "apellidos": p.pasajero.apellidos,
                    "punto_recogida": p.punto_recogida,
                    "lat_recogida": p.lat_recogida,
                    "lon_recogida": p.lon_recogida,
                    "punto_dejada": p.punto_dejada,
                    "lat_dejada": p.lat_dejada,
                    "lon_dejada": p.lon_dejada,
                }
                for p in pasajeros
            ]
        }

        return Response(data)


class RutaRecorridoView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, recorrido_id):
        recorrido = get_object_or_404(Recorrido, pk=recorrido_id)

        if not recorrido.lat_origen or not recorrido.lat_destino:
            return Response({"detalle": "Este recorrido no tiene coordenadas asignadas."}, status=400)

        origen = (recorrido.lon_origen, recorrido.lat_origen)
        destino = (recorrido.lon_destino, recorrido.lat_destino)

        ruta = obtener_ruta(origen, destino)

        return Response({"ruta": ruta})


class RecorridoDetalleView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, recorrido_id):
        recorrido = get_object_or_404(Recorrido, pk=recorrido_id)
        serializer = RecorridoDetalleSerializer(recorrido)
        return Response(serializer.data)
