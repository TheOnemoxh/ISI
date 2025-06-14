from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.conf import settings  # ✅ para usar AUTH_USER_MODEL sin circular imports
from core.utils.geo import calcular_distancia_km


# ---------------------------
# USUARIO PERSONALIZADO
# ---------------------------

class UsuarioManager(BaseUserManager):
    def create_user(self, correo, nombres, apellidos, celular, password=None, es_conductor=False):
        if not correo:
            raise ValueError('El usuario debe tener un correo electrónico')

        correo = self.normalize_email(correo)
        usuario = self.model(
            correo=correo,
            nombres=nombres,
            apellidos=apellidos,
            celular=celular,
            es_conductor=es_conductor
        )
        usuario.set_password(password)
        usuario.save(using=self._db)
        return usuario

    def create_superuser(self, correo, nombres, apellidos, celular, password):
        usuario = self.create_user(
            correo=correo,
            nombres=nombres,
            apellidos=apellidos,
            celular=celular,
            password=password,
            es_conductor=False
        )
        usuario.is_staff = True
        usuario.is_superuser = True
        usuario.save(using=self._db)
        return usuario


class Usuario(AbstractBaseUser, PermissionsMixin):
    correo = models.EmailField(unique=True)
    nombres = models.CharField(max_length=100)
    apellidos = models.CharField(max_length=100)
    celular = models.CharField(max_length=20)
    es_conductor = models.BooleanField(default=False)

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    objects = UsuarioManager()

    USERNAME_FIELD = 'correo'
    REQUIRED_FIELDS = ['nombres', 'apellidos', 'celular']

    def __str__(self):
        return self.correo


# ---------------------------
# VEHÍCULO
# ---------------------------

class Vehiculo(models.Model):
    usuario = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    marca = models.CharField(max_length=50)
    modelo = models.CharField(max_length=50)
    anio = models.PositiveIntegerField()
    color = models.CharField(max_length=30)
    placa = models.CharField(max_length=15)
    numero_asientos = models.PositiveIntegerField()

    def __str__(self):
        return f'{self.marca} {self.modelo} ({self.placa})'


# ---------------------------
# RECORRIDO
# ---------------------------

class Recorrido(models.Model):
    ESTADOS_CHOICES = [
        ('pendiente', 'Pendiente'),
        ('en_curso', 'En curso'),
        ('completado', 'Completado'),
        ('cancelado', 'Cancelado'),
    ]

    conductor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    origen = models.CharField(max_length=255)
    origen_lat = models.FloatField(null=True, blank=True)
    origen_lon = models.FloatField(null=True, blank=True)

    destino = models.CharField(max_length=255)
    destino_lat = models.FloatField(null=True, blank=True)
    destino_lon = models.FloatField(null=True, blank=True)

    fecha_hora_salida = models.DateTimeField()
    precio_total = models.DecimalField(max_digits=10, decimal_places=2)
    asientos_disponibles = models.PositiveIntegerField()

    distancia_km = models.FloatField(null=True, blank=True, help_text="Distancia real entre origen y destino en km")

    estado = models.CharField(max_length=20, choices=ESTADOS_CHOICES, default='pendiente')

    def __str__(self):
        return f'{self.origen} → {self.destino} ({self.fecha_hora_salida})'


# ---------------------------
# SOLICITUD DE VIAJE
# ---------------------------


class SolicitudDeViaje(models.Model):
    ESTADOS_CHOICES = [
        ('pendiente', 'Pendiente'),
        ('aceptada', 'Aceptada'),
        ('rechazada', 'Rechazada'),
    ]

    pasajero = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    recorrido = models.ForeignKey(Recorrido, on_delete=models.CASCADE)
    estado = models.CharField(max_length=20, choices=ESTADOS_CHOICES, default='pendiente')
    punto_recogida = models.CharField(max_length=100)
    punto_dejada = models.CharField(max_length=100)
    distancia_recorrida = models.FloatField(help_text="Distancia estimada en kilómetros", default=0)

    # Geolocalización
    lat_recogida = models.FloatField(null=True, blank=True)
    lon_recogida = models.FloatField(null=True, blank=True)
    lat_dejada = models.FloatField(null=True, blank=True)
    lon_dejada = models.FloatField(null=True, blank=True)

    def __str__(self):
        return f'{self.pasajero.correo} → {self.recorrido}'

    def save(self, *args, **kwargs):
        if self.lat_recogida and self.lon_recogida and self.lat_dejada and self.lon_dejada:
            self.distancia_recorrida = calcular_distancia_km(
                (self.lat_recogida, self.lon_recogida),
                (self.lat_dejada, self.lon_dejada)
            )

        if self.pk:
            estado_anterior = SolicitudDeViaje.objects.get(pk=self.pk).estado
        else:
            estado_anterior = None

        # ✅ Aceptar solicitud: reducir asientos si hay cupo
        if self.estado == 'aceptada' and estado_anterior != 'aceptada':
            if self.recorrido.asientos_disponibles <= 0:
                raise ValueError("No hay asientos disponibles en este recorrido.")
            self.recorrido.asientos_disponibles -= 1
            self.recorrido.save()

        # 🔄 Cambiar de aceptada a otro estado: liberar cupo
        if estado_anterior == 'aceptada' and self.estado != 'aceptada':
            self.recorrido.asientos_disponibles += 1
            self.recorrido.save()

        super().save(*args, **kwargs)

# ---------------------------
# CÁLCULO DE PRECIO
# ---------------------------

def calcular_precio_por_pasajero(recorrido):
    solicitudes = SolicitudDeViaje.objects.filter(recorrido=recorrido, estado='aceptada')
    pasajeros = solicitudes.count()
    if pasajeros == 0:
        return 0

    distancia_total = sum([s.distancia_recorrida for s in solicitudes])
    precio_base = distancia_total * 2000

    asientos_totales = recorrido.asientos_disponibles + pasajeros
    asientos_vacios = asientos_totales - pasajeros

    descuento_por_asiento_vacio = (3/5) * (precio_base / asientos_totales)
    total_a_repartir = precio_base - (asientos_vacios * descuento_por_asiento_vacio)

    precio_individual = total_a_repartir / pasajeros
    return round(precio_individual, 2)
