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
        coordsOrigen = (origen[1], origen[0])
        coordsDestino = (destino[1], destino[0])
        data = {'key': key, 'steps': True, 'alternatives': False, 'geometries': 'polyline', 'overview': 'full'}
        response = requests.get(url + f'/directions/driving/{coordsOrigen};{coordsDestino}', data)
        ruta = response['routes']
        distancia_metros = ruta[0]['distance']
        return round(distancia_metros / 1000, 2)  # en kilómetros
    except Exception as e:
        print("Error al calcular distancia:", e)
        return 0

def obtener_ruta(origen, destino):
    # origen y destino son (lon, lat) → como espera la API
    try:
        coordsOrigen = (origen[1], origen[0])
        coordsDestino = (destino[1], destino[0])
        data = {
            'key': key, 
            'steps': True, 
            'alternatives': False, 
            'geometries': 'polyline', 
            'overview': 'full'
        }
        response = requests.get(url + f'/directions/driving/{coordsOrigen};{coordsDestino}', data)
        ruta = response['routes'][0]
        leg = ruta['legs'][0]
        steps = []
        for step in leg['steps']:
            maneuver = step['maneuver']
            calle = step.get('name', '')

            instruccion = maneuver.get('type','continua').replace('_', ' ').title()
            modifier = maneuver.get('modifier', '')
            
            instruccion_parts = [instruccion]
            if modifier:
                instruccion_parts.append(modifier)
            if calle:
                instruccion_parts.append(f"en {calle}")
            
            instruccion_final = ' '.join(instruccion_parts)
            
            steps.append({
                'instruccion': instruccion_final,
                "distance_meters": round(step["distance"], 2),
                "duration_seconds": round(step["duration"], 2),
                'coordenadas': step['geometry']['coordinates'],
                'location': maneuver['location']
            })
        processed_route = {
            "summary": leg.get("summary", ""),
            "total_distance_meters": round(ruta["distance"], 2),
            "total_duration_seconds": round(ruta["duration"], 2),
            "route_geometry_encoded": ruta["geometry"], # Polyline codificada para el mapa
            "steps": steps
        }

        return processed_route

    except (KeyError, IndexError) as e:
        print(f"Error al procesar el JSON: {e}")
        return None
