import requests
from django.conf import settings

url = "https://us1.locationiq.com/v1"
key = settings.LOCATIONIQ_API_KEY

#Busca una dirección y retorna sus coordenadas (latitud, longitud)
def geocodificar_direccion(direccion):
    try:
        data = {'key': key,'q': direccion, 'format': 'json'}
        response = requests.get(url+'/search', data)
        coordenadas = response['lat']['lon']
        # Retorna como (lat, lon)
        return coordenadas[1], coordenadas[0]
    except Exception as e:
        print("Error al geocodificar:", e)
        return None, None


def calcular_distancia_km(origen, destino):
    try:
        coords = [(origen[1], origen[0]), (destino[1], destino[0])]
        data = {'key': key, 'steps': True, 'alternatives': False, 'geometries': 'polyline', 'overview': 'full'}
        response = requests.get(url + '/directions/driving/', data)
        ruta = response['routes']
        distancia_metros = ruta[0]['distance']
        return round(distancia_metros / 1000, 2)  # en kilómetros
    except Exception as e:
        print("Error al calcular distancia:", e)
        return 0

def obtener_ruta_coords(origen, destino):
    # origen y destino son (lon, lat) → como espera la API
    try:
        coords = [origen, destino]
        ruta = client.directions(coords, format='geojson')
        return ruta['features'][0]['geometry']['coordinates']
    except Exception as e:
        print("Error al calcular ruta:", e)
        return []
