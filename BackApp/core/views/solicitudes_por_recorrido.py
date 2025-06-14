# core/views/solicitudes_por_recorrido.py

from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from core.models import Recorrido, SolicitudDeViaje
from core.serializers import SolicitudDeViajeSerializer

class SolicitudesPorRecorridoView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, recorrido_id):
        try:
            recorrido = Recorrido.objects.get(id=recorrido_id)
        except Recorrido.DoesNotExist:
            return Response({'detalle': 'Recorrido no encontrado.'}, status=status.HTTP_404_NOT_FOUND)

        if recorrido.conductor != request.user:
            return Response({'detalle': 'No tienes permiso para ver las solicitudes de este recorrido.'}, status=status.HTTP_403_FORBIDDEN)

        solicitudes = SolicitudDeViaje.objects.filter(recorrido=recorrido).order_by('estado')
        serializer = SolicitudDeViajeSerializer(solicitudes, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
