from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from core.models import Recorrido

class ActualizarUbicacionConductorView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, recorrido_id):
        recorrido = get_object_or_404(Recorrido, pk=recorrido_id)

        if recorrido.conductor != request.user:
            return Response({'detalle': 'No tienes permiso para actualizar este recorrido.'}, status=403)

        lat = request.data.get('ubicacion_actual_lat')
        lon = request.data.get('ubicacion_actual_lon')

        if lat is None or lon is None:
            return Response({'error': 'Latitud y longitud son requeridas.'}, status=400)

        try:
            recorrido.ubicacion_actual_lat = float(lat)
            recorrido.ubicacion_actual_lon = float(lon)
            recorrido.save()
            return Response({'mensaje': 'Ubicación actual actualizada correctamente.'})
        except ValueError:
            return Response({'error': 'Coordenadas inválidas.'}, status=400)
