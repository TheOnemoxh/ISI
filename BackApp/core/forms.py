from django import forms
from .models import Recorrido, Usuario

class RecorridoForm(forms.ModelForm):
    class Meta:
        model = Recorrido
        fields = '__all__'

    def __init__(self, *args, **kwargs):
        super(RecorridoForm, self).__init__(*args, **kwargs)
        self.fields['conductor'].queryset = Usuario.objects.filter(es_conductor=True)
