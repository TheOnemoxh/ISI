from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models

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


class Vehiculo(models.Model):
    usuario = models.OneToOneField(Usuario, on_delete=models.CASCADE)
    marca = models.CharField(max_length=50)
    modelo = models.CharField(max_length=50)
    anio = models.PositiveIntegerField()
    color = models.CharField(max_length=30)
    placa = models.CharField(max_length=15)
    numero_asientos = models.PositiveIntegerField()

    def __str__(self):
        return f'{self.marca} {self.modelo} ({self.placa})'


class Recorrido(models.Model):
    ESTADOS_CHOICES = [
        ('pendiente', 'Pendiente'),
        ('en_curso', 'En curso'),
        ('completado', 'Completado'),
        ('cancelado', 'Cancelado'),
    ]

    conductor = models.ForeignKey(Usuario, on_delete=models.CASCADE)
    origen = models.CharField(max_length=100)
    destino = models.CharField(max_length=100)
    fecha_hora_salida = models.DateTimeField()
    precio_total = models.DecimalField(max_digits=10, decimal_places=2)
    estado = models.CharField(max_length=20, choices=ESTADOS_CHOICES, default='pendiente')
    asientos_disponibles = models.PositiveIntegerField()

    # Nuevos campos de geolocalización
    lat_origen = models.FloatField(null=True, blank=True)
    lon_origen = models.FloatField(null=True, blank=True)
    lat_destino = models.FloatField(null=True, blank=True)
    lon_destino = models.FloatField(null=True, blank=True)
    distancia_km = models.FloatField(null=True, blank=True, help_text="Distancia real entre origen y destino en km")

    def __str__(self):
        return f'{self.origen} → {self.destino} ({self.fecha_hora_salida})'


class SolicitudDeViaje(models.Model):
    ESTADOS_CHOICES = [
        ('pendiente', 'Pendiente'),
        ('aceptada', 'Aceptada'),
        ('rechazada', 'Rechazada'),
    ]

    pasajero = models.ForeignKey(Usuario, on_delete=models.CASCADE)
    recorrido = models.ForeignKey(Recorrido, on_delete=models.CASCADE)
    estado = models.CharField(max_length=20, choices=ESTADOS_CHOICES, default='pendiente')
    punto_recogida = models.CharField(max_length=100)
    punto_dejada = models.CharField(max_length=100)
    distancia_recorrida = models.FloatField(help_text="Distancia estimada en kilómetros", default=0)

    # Nuevos campos de geolocalización
    lat_recogida = models.FloatField(null=True, blank=True)
    lon_recogida = models.FloatField(null=True, blank=True)
    lat_dejada = models.FloatField(null=True, blank=True)
    lon_dejada = models.FloatField(null=True, blank=True)

    def __str__(self):
        return f'{self.pasajero.correo} → {self.recorrido}'

    def save(self, *args, **kwargs):
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
