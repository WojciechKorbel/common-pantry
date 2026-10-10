from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from .models import FridgeItem, ItemStatus
from .serializers import FridgeItemSerializer


class FridgeItemListAPIView(generics.ListCreateAPIView):
    serializer_class = FridgeItemSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = FridgeItem.objects.filter(status=ItemStatus.ACTIVE).order_by('expiry_date')

        household_id = self.request.query_params.get('household_id')
        if household_id:
            queryset = queryset.filter(household_id=household_id)
        return queryset

    def perform_create(self, serializer):
        serializer.save(added_by=self.request.user)