import requests
from django.conf import settings

url = "https://us1.locationiq.com/v1"
key = settings.LOCATIONIQ_API_KEY


def geocodificar_direccion(direccion):
    try:
        params = {'key': key, 'q': direccion, 'format': 'json'}
        response = requests.get(f"{url}/search", params=params)
        data = response.json()
        lat = float(data[0]['lat'])
        lon = float(data[0]['lon'])
        return lat, lon
    except Exception as e:
        print("Error al geocodificar:", e)
        return None, None


def calcular_distancia_km(origen, destino):
    try:
        coordsOrigen = f"{origen[1]},{origen[0]}"
        coordsDestino = f"{destino[1]},{destino[0]}"
        params = {
            'key': key,
            'steps': 'true',
            'alternatives': 'false',
            'geometries': 'polyline',
            'overview': 'full'
        }
        response = requests.get(f"{url}/directions/driving/{coordsOrigen};{coordsDestino}", params=params)
        data = response.json()
        distancia_metros = data['routes'][0]['distance']
        return round(distancia_metros / 1000, 2)
    except Exception as e:
        print("Error al calcular distancia:", e)
        return 0


def obtener_ruta(origen, destino):
    try:
        coordsOrigen = f"{origen[1]},{origen[0]}"
        coordsDestino = f"{destino[1]},{destino[0]}"
        params = {
            'key': key,
            'steps': 'true',
            'alternatives': 'false',
            'geometries': 'polyline',
            'overview': 'full'
        }
        response = requests.get(f"{url}/directions/driving/{coordsOrigen};{coordsDestino}", params=params)
        data = response.json()
        ruta = data['routes'][0]
        leg = ruta['legs'][0]
        steps = []

        for step in leg['steps']:
            maneuver = step['maneuver']
            calle = step.get('name', '')
            instruccion = maneuver.get('type', 'continúa').replace('_', ' ').title()
            modifier = maneuver.get('modifier', '')
            
            partes = [instruccion]
            if modifier:
                partes.append(modifier)
            if calle:
                partes.append(f"en {calle}")
            
            instruccion_final = ' '.join(partes)

            steps.append({
                'instruccion': instruccion_final,
                'distance_meters': round(step['distance'], 2),
                'duration_seconds': round(step['duration'], 2),
                'coordenadas': step['geometry']['coordinates'],
                'location': maneuver['location']
            })

        return {
            "summary": leg.get("summary", ""),
            "total_distance_meters": round(ruta["distance"], 2),
            "total_duration_seconds": round(ruta["duration"], 2),
            "route_geometry_encoded": ruta["geometry"],  # Polyline codificada
            "steps": steps
        }

    except Exception as e:
        print(f"Error al procesar la ruta: {e}")
        return None

def obtener_ruta_coords(origen, destino):
    """
    Retorna una lista de coordenadas (lon, lat) que forman la ruta.
    """
    try:
        coordsOrigen = f"{origen[1]},{origen[0]}"
        coordsDestino = f"{destino[1]},{destino[0]}"
        params = {
            'key': key,
            'overview': 'full',
            'geometries': 'geojson'
        }
        response = requests.get(f"{url}/directions/driving/{coordsOrigen};{coordsDestino}", params=params)
        data = response.json()
        return data['routes'][0]['geometry']['coordinates']
    except Exception as e:
        print(f"Error al obtener coordenadas de la ruta: {e}")
        return []
