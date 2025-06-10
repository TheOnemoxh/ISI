from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from core.models import Recorrido, SolicitudDeViaje
from core.serializers import HistorialRecorridoConductorSerializer, HistorialPasajeroSerializer

class HistorialConductorView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        recorridos = Recorrido.objects.filter(conductor=request.user, estado='completado')
        serializer = HistorialRecorridoConductorSerializer(recorridos, many=True)
        return Response(serializer.data)


class HistorialPasajeroView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        solicitudes = SolicitudDeViaje.objects.filter(
            pasajero=request.user,
            estado='aceptada',
            recorrido__estado='completado'
        )
        serializer = HistorialPasajeroSerializer(solicitudes, many=True)
        return Response(serializer.data)
