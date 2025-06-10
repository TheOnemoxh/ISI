from rest_framework import serializers
from core.models import Usuario

class UsuarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuario
        fields = ['id', 'correo', 'nombres', 'apellidos', 'celular', 'es_conductor']
        read_only_fields = ['id', 'correo', 'es_conductor']

from core.models import Vehiculo

class VehiculoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehiculo
        fields = ['marca', 'modelo', 'anio', 'color', 'placa', 'numero_asientos']

from core.models import Recorrido

class RecorridoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Recorrido
        fields = [
            'id', 'origen', 'destino', 'fecha_hora_salida',
            'precio_total', 'estado', 'asientos_disponibles'
        ]
        read_only_fields = ['estado']

from core.models import SolicitudDeViaje

class SolicitudDeViajeSerializer(serializers.ModelSerializer):
    class Meta:
        model = SolicitudDeViaje
        fields = [
            'id', 'recorrido', 'punto_recogida', 'punto_dejada',
            'distancia_recorrida', 'estado'
        ]
        read_only_fields = ['estado']

class SolicitudDeViajeDetalleSerializer(serializers.ModelSerializer):
    pasajero_nombre = serializers.CharField(source='pasajero.nombres', read_only=True)
    recorrido_origen = serializers.CharField(source='recorrido.origen', read_only=True)
    recorrido_destino = serializers.CharField(source='recorrido.destino', read_only=True)

    class Meta:
        model = SolicitudDeViaje
        fields = [
            'id', 'recorrido', 'pasajero_nombre', 'punto_recogida',
            'punto_dejada', 'distancia_recorrida', 'estado',
            'recorrido_origen', 'recorrido_destino'
        ]

class MisSolicitudesSerializer(serializers.ModelSerializer):
    recorrido_origen = serializers.CharField(source='recorrido.origen', read_only=True)
    recorrido_destino = serializers.CharField(source='recorrido.destino', read_only=True)
    fecha_hora = serializers.DateTimeField(source='recorrido.fecha_hora_salida', read_only=True)

    class Meta:
        model = SolicitudDeViaje
        fields = [
            'id', 'recorrido', 'recorrido_origen', 'recorrido_destino',
            'fecha_hora', 'estado', 'punto_recogida', 'punto_dejada', 'distancia_recorrida'
        ]


class PasajeroAceptadoSerializer(serializers.ModelSerializer):
    nombres = serializers.CharField(source='pasajero.nombres', read_only=True)
    apellidos = serializers.CharField(source='pasajero.apellidos', read_only=True)
    telefono = serializers.CharField(source='pasajero.celular', read_only=True)

    class Meta:
        model = SolicitudDeViaje
        fields = [
            'id', 'nombres', 'apellidos', 'telefono',
            'punto_recogida', 'punto_dejada'
        ]

class HistorialRecorridoConductorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Recorrido
        fields = ['id', 'origen', 'destino', 'fecha_hora_salida', 'precio_total']


class HistorialPasajeroSerializer(serializers.ModelSerializer):
    recorrido_origen = serializers.CharField(source='recorrido.origen', read_only=True)
    recorrido_destino = serializers.CharField(source='recorrido.destino', read_only=True)
    fecha = serializers.DateTimeField(source='recorrido.fecha_hora_salida', read_only=True)

    class Meta:
        model = SolicitudDeViaje
        fields = ['id', 'recorrido_origen', 'recorrido_destino', 'fecha', 'estado']
