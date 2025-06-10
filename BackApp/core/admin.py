from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .forms import RecorridoForm
from .models import Usuario, Vehiculo, Recorrido, SolicitudDeViaje


class UsuarioAdmin(UserAdmin):
    model = Usuario
    list_display = ('correo', 'nombres', 'apellidos', 'es_conductor', 'is_staff', 'is_superuser')
    list_filter = ('es_conductor', 'is_staff', 'is_superuser')
    search_fields = ('correo', 'nombres', 'apellidos', 'celular')
    ordering = ('correo',)

    fieldsets = (
        (None, {'fields': ('correo', 'password')}),
        ('Información Personal', {'fields': ('nombres', 'apellidos', 'celular', 'es_conductor')}),
        ('Permisos', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        ('Fechas importantes', {'fields': ('last_login',)}),
    )

    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('correo', 'nombres', 'apellidos', 'celular', 'es_conductor', 'password1', 'password2'),
        }),
    )

admin.site.register(Usuario, UsuarioAdmin)

@admin.register(Vehiculo)
class VehiculoAdmin(admin.ModelAdmin):
    list_display = ('usuario', 'marca', 'modelo', 'placa', 'numero_asientos')
    search_fields = ('marca', 'modelo', 'placa', 'usuario__correo')

@admin.register(Recorrido)
class RecorridoAdmin(admin.ModelAdmin):
    form = RecorridoForm
    list_display = ('conductor', 'origen', 'destino', 'fecha_hora_salida', 'estado', 'asientos_disponibles')
    search_fields = ('origen', 'destino', 'conductor__correo')
    list_filter = ('estado',)



@admin.register(SolicitudDeViaje)
class SolicitudAdmin(admin.ModelAdmin):
    list_display = ('pasajero', 'recorrido', 'estado', 'punto_recogida', 'punto_dejada', 'distancia_recorrida')
    list_filter = ('estado',)
    search_fields = ('pasajero__correo', 'recorrido__origen', 'recorrido__destino')
