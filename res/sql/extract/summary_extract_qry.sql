SELECT 
--COLUMNS
    Code, U_BookingNumber, U_BookingDate, U_ClientName, U_SAPClient, U_ClientVatStatus, U_TruckerName, U_SAPTrucker, U_TruckerVatStatus, U_VehicleTypeCap, U_ISLAND, U_ISLAND_D, U_IFINTERISLAND, U_DeliveryStatus, U_DeliveryDateDTR,
    U_DeliveryDatePOD, U_ClientReceivedDate, U_ActualDateRec_Intitial, U_InitialHCRecDate, U_ActualHCRecDate, U_DateReturned, U_VerifiedDateHC, U_PTFNo, U_DateForwardedBT, U_PODSONum, U_GrossClientRates,
    U_GrossClientRatesTax, U_GrossTruckerRates, U_GrossTruckerRatesTax, U_GrossProfitNet, U_TotalInitialClient, U_TotalInitialTruckers, U_TotalGrossProfit, U_BillingStatus, U_PODStatusPayment, U_PaymentReference,
    U_PaymentStatus, U_ProofOfPayment, U_TotalRecClients, U_TotalPayable, U_PVNo, U_TotalAR, U_VarAR, U_TotalAP, U_VarTP, U_APDocNum, U_ARDocNum, U_DeliveryOrigin, U_Destination, U_PODStatusDetail, U_Remarks, U_WaybillNo, U_ServiceType,
    U_InvoiceNo
--COLUMNS
FROM SUMMARY_EXTRACT WITH (NOLOCK) 