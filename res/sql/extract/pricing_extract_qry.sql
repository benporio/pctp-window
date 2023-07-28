SELECT 
--COLUMNS
    U_BookingNumber, DisableSomeFields, DisableSomeFields2, Code, U_BookingId, U_BookingDate, U_PODNum, U_CustomerName, U_ClientTag, U_ClientProject, U_TruckerName, U_TruckerTag, U_VehicleTypeCap, U_DeliveryStatus,
    U_TripType, U_NoOfDrops, U_GrossClientRates, U_ISLAND, U_ISLAND_D, U_IFINTERISLAND, U_GrossClientRatesTax, U_RateBasis, U_TaxType, U_GrossProfitNet, U_Demurrage, U_AddtlDrop, U_BoomTruck, U_Manpower, U_Backload,
    U_TotalAddtlCharges, U_Demurrage2, U_AddtlDrop2, U_BoomTruck2, U_Manpower2, U_Backload2, U_totalAddtlCharges2, U_Demurrage3, U_AddtlCharges, U_GrossProfit, U_TotalInitialClient, U_TotalInitialTruckers, U_TotalGrossProfit,
    U_ClientTag2, U_GrossTruckerRates, U_GrossTruckerRatesTax, U_RateBasisT, U_TaxTypeT, U_Demurrage4, U_AddtlCharges2, U_GrossProfitC, BillingNum, TPNum, U_ActualBilledRate, U_BillingRateAdjustments,
    U_BillingActualDemurrage, U_ActualAddCharges, U_TotalRecClients, U_TotalAR, U_VarAR, U_PODSONum, U_ActualRates, U_TPRateAdjustments, U_TPActualDemurrage, U_ActualCharges, U_TPBoomTruck2, U_OtherCharges,
    U_TotalPayable, U_PVNo, U_TotalAP, U_VarTP, U_APDocNum, U_Paid, U_DocNum, U_DeliveryOrigin, U_Destination, U_RemarksDTR, U_RemarksPOD, U_PODDocNum
--COLUMNS
FROM PRICING_EXTRACT  WITH (NOLOCK) 