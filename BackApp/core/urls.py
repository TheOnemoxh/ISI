from django.urls import path
from core.views.auth_views import RegistroView, LoginView, UsuarioActualView
from core.views.vehiculo_views import VehiculoView
from core.views.recorrido_views import RecorridoView
from core.views.solicitud_views import SolicitudDeViajeView
from core.views.solicitud_views import (
    SolicitudDeViajeView,
    SolicitudesParaConductorView,
    CambiarEstadoSolicitudView
)
from core.views.solicitud_views import MisSolicitudesView
from core.views.recorrido_views import PrecioPorPasajeroView
from core.views.recorrido_views import PasajerosAceptadosView
from core.views.recorrido_views import CambiarEstadoRecorridoView
from core.views.historial_views import HistorialConductorView, HistorialPasajeroView
from core.views.recorrido_views import RecorridoMapaView
from core.views.recorrido_views import RutaRecorridoView



urlpatterns = [
    path('recorridos/<int:recorrido_id>/ruta/', RutaRecorridoView.as_view()),
    path('registro/', RegistroView.as_view()),
    path('login/', LoginView.as_view()),
    path('usuario/', UsuarioActualView.as_view()),
    path('vehiculo/', VehiculoView.as_view()),
    path('recorridos/', RecorridoView.as_view()),
    path('solicitud/', SolicitudDeViajeView.as_view()),
    path('solicitudes/', SolicitudesParaConductorView.as_view()),
    path('solicitudes/<int:pk>/<str:accion>/', CambiarEstadoSolicitudView.as_view()),
    path('mis-solicitudes/', MisSolicitudesView.as_view()),  # 👈 nuevo endpoint
    path('recorridos/<int:recorrido_id>/precio-por-pasajero/', PrecioPorPasajeroView.as_view()),
    path('recorridos/<int:recorrido_id>/pasajeros/', PasajerosAceptadosView.as_view()),
    path('historial/conductor/', HistorialConductorView.as_view()),
    path('historial/pasajero/', HistorialPasajeroView.as_view()),
    # BIEN (el mapa está antes, se evalúa primero)
    path('recorridos/<int:recorrido_id>/mapa/', RecorridoMapaView.as_view()),
    path('recorridos/<int:recorrido_id>/<str:nuevo_estado>/', CambiarEstadoRecorridoView.as_view()),

]

