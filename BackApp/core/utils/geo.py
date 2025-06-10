import openrouteservice
from django.conf import settings

client = openrouteservice.Client(key=settings.ORS_API_KEY)


def geocodificar_direccion(direccion):
    try:
        resultado = client.pelias_search(text=direccion)
        coordenadas = resultado['features'][0]['geometry']['coordinates']
        # Retorna como (lat, lon)
        return coordenadas[1], coordenadas[0]
    except Exception as e:
        print("Error al geocodificar:", e)
        return None, None


def calcular_distancia_km(origen, destino):
    try:
        coords = [(origen[1], origen[0]), (destino[1], destino[0])]
        ruta = client.directions(coords)
        distancia_metros = ruta['routes'][0]['summary']['distance']
        return round(distancia_metros / 1000, 2)  # en kilómetros
    except Exception as e:
        print("Error al calcular distancia:", e)
        return 0



client = openrouteservice.Client(key=settings.OPENROUTESERVICE_API_KEY)

def obtener_ruta_coords(origen, destino):
    # origen y destino son (lon, lat) → como espera la API
    try:
        coords = [origen, destino]
        ruta = client.directions(coords, format='geojson')
        return ruta['features'][0]['geometry']['coordinates']
    except Exception as e:
        print("Error al calcular ruta:", e)
        return []
