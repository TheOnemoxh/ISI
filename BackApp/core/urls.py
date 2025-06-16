from django.urls import path
from core.views.auth_views import RegistroView, LoginView, UsuarioActualView
from core.views.vehiculo_views import VehiculoView
from core.views.recorrido_views import (
    RecorridoView,
    PrecioPorPasajeroView,
    PasajerosAceptadosView,
    CambiarEstadoRecorridoView,
    RecorridoMapaView,
    RutaRecorridoView,
    RecorridoDetalleView
)
from core.views.solicitud_views import (
    SolicitudDeViajeView,
    SolicitudesParaConductorView,
    CambiarEstadoSolicitudView,
    MisSolicitudesView
)
from core.views.historial_views import HistorialConductorView, HistorialPasajeroView
from core.views.autocomplete_view import AutocompleteView
from core.views.solicitudes_por_recorrido import SolicitudesPorRecorridoView
from core.views.ubicacion_views import ActualizarUbicacionConductorView

urlpatterns = [
    # 👇 ENDPOINT DE UBICACIÓN (debe ir antes de <str:nuevo_estado>)
    path('ubicacion/recorrido/<int:recorrido_id>/', ActualizarUbicacionConductorView.as_view(), name='actualizar_ubicacion'),

    # 📍 Recorridos
    path('recorridos/', RecorridoView.as_view()),
    path('recorridos/<int:recorrido_id>/detalles/', RecorridoDetalleView.as_view()),
    path('recorridos/<int:recorrido_id>/ruta/', RutaRecorridoView.as_view()),
    path('recorridos/<int:recorrido_id>/precio-por-pasajero/', PrecioPorPasajeroView.as_view()),
    path('recorridos/<int:recorrido_id>/pasajeros/', PasajerosAceptadosView.as_view()),
    path('recorridos/<int:recorrido_id>/mapa/', RecorridoMapaView.as_view()),
    path('recorridos/<int:recorrido_id>/solicitudes/', SolicitudesPorRecorridoView.as_view(), name='solicitudes-por-recorrido'),

    # ❗ ESTA VA AL FINAL PARA NO INTERCEPTAR OTRAS RUTAS
    path('recorridos/<int:recorrido_id>/<str:nuevo_estado>/', CambiarEstadoRecorridoView.as_view()),

    # 🚗 Vehículo
    path('vehiculo/', VehiculoView.as_view()),

    # 👤 Usuario
    path('registro/', RegistroView.as_view()),
    path('login/', LoginView.as_view()),
    path('usuario/', UsuarioActualView.as_view()),

    # 📩 Solicitudes
    path('solicitud/', SolicitudDeViajeView.as_view()),
    path('solicitudes/', SolicitudesParaConductorView.as_view()),
    path('solicitudes/<int:pk>/<str:accion>/', CambiarEstadoSolicitudView.as_view()),
    path('mis-solicitudes/', MisSolicitudesView.as_view()),

    # 📚 Historial
    path('historial/conductor/', HistorialConductorView.as_view()),
    path('historial/pasajero/', HistorialPasajeroView.as_view()),

    # 🔍 Autocompletado
    path('autocomplete/', AutocompleteView.as_view()),
]
