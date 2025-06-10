from core.models import SolicitudDeViaje

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
