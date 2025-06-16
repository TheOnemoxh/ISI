from rest_framework import serializers
from core.models import Usuario
from rest_framework import serializers
from core.models import SolicitudDeViaje

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
            'id',
            'origen', 'origen_lat', 'origen_lon',
            'destino', 'destino_lat', 'destino_lon',
            'fecha_hora_salida', 'precio_total',
            'asientos_disponibles', 'distancia_km',
            'estado',
            'ubicacion_actual_lat',  # ← nuevo
            'ubicacion_actual_lon'
        ]



class SolicitudDeViajeSerializer(serializers.ModelSerializer):
    class Meta:
        model = SolicitudDeViaje
        fields = [
            'id',
            'recorrido',
            'punto_recogida', 'lat_recogida', 'lon_recogida',
            'punto_dejada', 'lat_dejada', 'lon_dejada',
            'distancia_recorrida',
            'estado'
        ]
        read_only_fields = ['distancia_recorrida', 'estado']


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

from rest_framework import serializers
from core.models import Recorrido, Usuario, Vehiculo

class ConductorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuario
        fields = ['nombres', 'apellidos', 'correo', 'celular']

class VehiculoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehiculo
        fields = ['marca', 'modelo', 'anio', 'color', 'placa', 'numero_asientos']

class RecorridoDetalleSerializer(serializers.ModelSerializer):
    conductor = ConductorSerializer(read_only=True)
    vehiculo = serializers.SerializerMethodField()

    class Meta:
        model = Recorrido
        fields = [
            'id', 'origen', 'destino', 'fecha_hora_salida', 'precio_total',
            'estado', 'asientos_disponibles', 'distancia_km',
            'conductor', 'vehiculo'
        ]

    def get_vehiculo(self, obj):
        try:
            vehiculo = Vehiculo.objects.get(usuario=obj.conductor)
            return VehiculoSerializer(vehiculo).data
        except Vehiculo.DoesNotExist:
            return None
class SolicitudPorRecorridoSerializer(serializers.ModelSerializer):
    nombres = serializers.CharField(source='pasajero.nombres', read_only=True)
    apellidos = serializers.CharField(source='pasajero.apellidos', read_only=True)
    telefono = serializers.CharField(source='pasajero.celular', read_only=True)

    class Meta:
        model = SolicitudDeViaje
        fields = [
            'id',
            'nombres', 'apellidos', 'telefono',
            'punto_recogida', 'lat_recogida', 'lon_recogida',
            'punto_dejada', 'lat_dejada', 'lon_dejada',
            'distancia_recorrida', 'estado'
        ]
