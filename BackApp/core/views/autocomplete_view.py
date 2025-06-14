# core/views/autocomplete_view.py
import requests
from django.conf import settings
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny

class AutocompleteView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        query = request.query_params.get("query")
        if not query:
            return Response({"error": "Parámetro 'query' requerido"}, status=400)

        url = "https://us1.locationiq.com/v1/autocomplete.php"
        params = {
            "key": settings.LOCATIONIQ_API_KEY,
            "q": query,
            "format": "json",
            "limit": 5,
        }

        try:
            response = requests.get(url, params=params)
            data = response.json()

            resultados = [
                {
                    "display_name": lugar["display_name"],
                    "lat": float(lugar["lat"]),
                    "lon": float(lugar["lon"])
                }
                for lugar in data
            ]
            return Response(resultados)

        except Exception as e:
            print("Error al llamar a LocationIQ:", e)
            return Response({"error": "No se pudo obtener sugerencias"}, status=500)
