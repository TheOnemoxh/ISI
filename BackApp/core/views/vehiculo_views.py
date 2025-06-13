from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from core.models import Vehiculo
from core.serializers import VehiculoSerializer

class VehiculoView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            vehiculo = Vehiculo.objects.get(usuario=request.user)
            serializer = VehiculoSerializer(vehiculo)
            return Response(serializer.data)
        except Vehiculo.DoesNotExist:
            return Response({'detalle': 'El usuario no tiene vehículo'}, status=404)

    def post(self, request):
        if hasattr(request.user, 'vehiculo'):
            return Response({'detalle': 'El usuario ya tiene un vehículo registrado'}, status=400)

        serializer = VehiculoSerializer(data=request.data)
        if serializer.is_valid():
            # ✅ Guardar el vehículo asociado al usuario
            vehiculo = serializer.save(usuario=request.user)
            
            # ✅ Actualizar el usuario a "conductor"
            request.user.es_conductor = True
            request.user.save()

            return Response(VehiculoSerializer(vehiculo).data, status=201)
        return Response(serializer.errors, status=400)
    
    def patch(self, request):
        try:
            vehiculo = Vehiculo.objects.get(usuario=request.user)
        except Vehiculo.DoesNotExist:
            return Response({'detalle': 'El usuario no tiene vehículo'}, status=404)

        serializer = VehiculoSerializer(vehiculo, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)
