SELECT 
--COLUMNS
    X.U_BookingNumber, 
    X.pr_DisableSomeFields AS DisableSomeFields, 
    X.pr_DisableSomeFields2 AS DisableSomeFields2, 
    X.pr_Code AS Code, 
    X.U_BookingNumber AS U_BookingId, 
    X.U_BookingDate, 
    X.pr_U_PODNum AS U_PODNum, 
    X.U_CustomerName, 
    X.U_ClientTag, 
    X.U_ClientProject, 
    X.U_TruckerName, 
    X.U_TruckerTag, 
    X.U_VehicleTypeCap, 
    X.U_DeliveryStatus,
    X.U_TripType, 
    X.U_NoOfDrops, 
    X.U_GrossClientRates, 
    X.U_ISLAND, 
    X.U_ISLAND_D, 
    X.U_IFINTERISLAND, 
    X.U_GrossClientRatesTax, 
    X.pr_U_RateBasis AS U_RateBasis, 
    X.pr_U_TaxType AS U_TaxType, 
    X.U_GrossProfitNet, 
    X.U_Demurrage, 
    X.pr_U_AddtlDrop AS U_AddtlDrop, 
    X.pr_U_BoomTruck AS U_BoomTruck, 
    X.pr_U_Manpower AS U_Manpower, 
    X.pr_U_BackLoad AS U_Backload,
    X.U_TotalAddtlCharges, 
    X.U_Demurrage2, 
    X.U_AddtlDrop2, 
    X.pr_U_BoomTruck2 AS U_BoomTruck2, 
    X.U_Manpower2, 
    X.U_Backload2, 
    X.U_totalAddtlCharges2, 
    X.U_Demurrage3, 
    X.pr_U_Addtlcharges AS U_AddtlCharges, 
    X.U_GrossProfit, 
    X.U_TotalInitialClient, 
    X.U_TotalInitialTruckers, 
    X.U_TotalGrossProfit,
    X.U_ClientTag2, 
    X.U_GrossTruckerRates, 
    X.U_GrossTruckerRatesTax, 
    X.U_RateBasisT, 
    X.U_TaxTypeT, 
    X.U_Demurrage4, 
    X.U_AddtlCharges2, 
    X.U_GrossProfitC, 
    X.U_ActualBilledRate, 
    X.U_BillingRateAdjustments,
    X.U_BillingActualDemurrage, 
    X.U_ActualAddCharges, 
    X.U_TotalRecClients, 
    X.U_TotalAR, 
    X.U_VarAR, 
    X.U_PODSONum, 
    X.U_ActualRates, 
    X.U_TPRateAdjustments, 
    X.U_TPActualDemurrage, 
    X.U_ActualCharges, 
    X.U_TPBoomTruck2, 
    X.U_OtherCharges,
    X.U_TotalPayable, 
    X.U_PVNo, 
    X.U_TotalAP, 
    X.U_VarTP, 
    X.pr_U_APDocNum AS U_APDocNum, 
    X.U_Paid, 
    X.U_DocNum, 
    X.U_DeliveryOrigin, 
    X.U_Destination, 
    X.U_RemarksDTR, 
    X.U_RemarksPOD, 
    X.U_PODDocNum
--COLUMNS
FROM PCTP_UNIFIED X  WITH (NOLOCK) 