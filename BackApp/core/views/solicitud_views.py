from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from django.shortcuts import get_object_or_404

from core.models import SolicitudDeViaje, Recorrido
from core.serializers import (
    SolicitudDeViajeSerializer,
    SolicitudDeViajeDetalleSerializer,
    MisSolicitudesSerializer
)
from core.utils.geo import geocodificar_direccion, calcular_distancia_km


class SolicitudDeViajeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        data = request.data
        data['pasajero'] = request.user.id

        # Verificar si ya solicitó este recorrido
        # if SolicitudDeViaje.objects.filter(
        #     recorrido_id=data['recorrido'],
        #     pasajero=request.user
        # ).exists():
        #     return Response({'detalle': 'Ya enviaste una solicitud a este recorrido.'}, status=400)

        serializer = SolicitudDeViajeSerializer(data=data)
        if serializer.is_valid():
            solicitud = serializer.save(pasajero=request.user)

            # 🔍 Geolocalización
            lat_r, lon_r = geocodificar_direccion(solicitud.punto_recogida)
            lat_d, lon_d = geocodificar_direccion(solicitud.punto_dejada)

            # 📏 Calcular distancia real
            distancia = calcular_distancia_km((lat_r, lon_r), (lat_d, lon_d))

            # 💾 Guardar coordenadas y distancia
            solicitud.lat_recogida = lat_r
            solicitud.lon_recogida = lon_r
            solicitud.lat_dejada = lat_d
            solicitud.lon_dejada = lon_d
            solicitud.distancia_recorrida = distancia
            solicitud.save()

            return Response(SolicitudDeViajeSerializer(solicitud).data, status=201)

        return Response(serializer.errors, status=400)


class SolicitudesParaConductorView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not request.user.es_conductor:
            return Response({'detalle': 'Solo conductores pueden ver estas solicitudes.'}, status=403)

        recorridos = Recorrido.objects.filter(conductor=request.user)
        solicitudes = SolicitudDeViaje.objects.filter(recorrido__in=recorridos)
        serializer = SolicitudDeViajeDetalleSerializer(solicitudes, many=True)
        return Response(serializer.data)


class CambiarEstadoSolicitudView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk, accion):
        solicitud = get_object_or_404(SolicitudDeViaje, pk=pk)

        if solicitud.recorrido.conductor != request.user:
            return Response({'detalle': 'No tienes permiso para modificar esta solicitud.'}, status=403)

        if accion == 'aceptar':
            solicitud.estado = 'aceptada'
        elif accion == 'rechazar':
            solicitud.estado = 'rechazada'
        else:
            return Response({'detalle': 'Acción inválida.'}, status=400)

        solicitud.save()
        return Response({'mensaje': f'Solicitud {accion} correctamente.'})


class MisSolicitudesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        solicitudes = SolicitudDeViaje.objects.filter(pasajero=request.user)
        serializer = MisSolicitudesSerializer(solicitudes, many=True)
        return Response(serializer.data)
