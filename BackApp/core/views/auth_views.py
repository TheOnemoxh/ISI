from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from core.models import Usuario
from rest_framework.permissions import AllowAny
from django.contrib.auth import authenticate
from rest_framework.permissions import IsAuthenticated
from core.serializers import UsuarioSerializer

from rest_framework.response import Response

from rest_framework import status


class UsuarioActualView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UsuarioSerializer(request.user)
        return Response(serializer.data)

    def patch(self, request):
        serializer = UsuarioSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)



class RegistroView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        data = request.data
        correo = data.get('correo')
        nombres = data.get('nombres')
        apellidos = data.get('apellidos')
        celular = data.get('celular')
        password = data.get('password')
        es_conductor = data.get('es_conductor', False)

        if Usuario.objects.filter(correo=correo).exists():
            return Response({'error': 'El correo ya está registrado'}, status=400)

        user = Usuario.objects.create_user(
            correo=correo,
            nombres=nombres,
            apellidos=apellidos,
            celular=celular,
            password=password,
            es_conductor=es_conductor
        )
        refresh = RefreshToken.for_user(user)
        return Response({
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'usuario_id': user.id
        })

class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        correo = request.data.get('correo')
        password = request.data.get('password')
        user = authenticate(request, correo=correo, password=password)

        if user is not None:
            refresh = RefreshToken.for_user(user)
            return Response({
                'access': str(refresh.access_token),
                'refresh': str(refresh),
                'usuario_id': user.id
            })
        else:
            return Response({'error': 'Credenciales inválidas'}, status=401)
