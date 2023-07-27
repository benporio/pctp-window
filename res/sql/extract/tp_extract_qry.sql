SELECT 
--COLUMNS
    DisableTableRow, U_BookingNumber, DisableSomeFields, Code, U_BookingId, U_BookingDate, U_PODNum, U_PODSONum, U_ClientName, U_TruckerName, U_TruckerSAP, U_PlateNumber, U_VehicleTypeCap, U_ISLAND, U_ISLAND_D, 
    U_IFINTERISLAND, U_DeliveryStatus, U_DeliveryDatePOD, U_NoOfDrops, U_TripType, U_Receivedby, U_ClientReceivedDate, U_ActualDateRec_Intitial, U_ActualHCRecDate, U_DateReturned, U_PODinCharge, U_VerifiedDateHC, 
    U_TPStatus, U_Aging, U_GrossTruckerRates, U_RateBasis, U_GrossTruckerRatesN, U_TaxType, U_Demurrage, U_AddtlDrop, U_BoomTruck, U_BoomTruck2, U_Manpower, U_BackLoad, U_Addtlcharges, U_DemurrageN, 
    U_AddtlChargesN, U_ActualRates, U_RateAdjustments, U_ActualDemurrage, U_ActualCharges, U_OtherCharges, WaivedDaysx, U_ClientSubOverdue, U_ClientPenaltyCalc, xHolidayOrWeekend, U_InteluckPenaltyCalc, 
    U_InitialHCRecDate, U_DeliveryDateDTR, U_TotalInitialTruckers, U_LostPenaltyCalc, U_TotalSubPenalty, U_TotalPenaltyWaived, U_TotalPenalty, U_TotalPayable, U_EWT2307, U_TotalPayableRec, U_PVNo, U_ORRefNo, U_TPincharge, 
    U_CAandDP, U_Interest, U_OtherDeductions, U_TOTALDEDUCTIONS, U_REMARKS1, U_TotalAP, U_VarTP, U_APInvLineNum, U_PercPenaltyCharge, ExtraDays, U_DocNum, U_Paid, U_OtherPODDoc, U_DeliveryOrigin, U_Remarks2, 
    U_RemarksPOD, U_GroupProject, U_Destination, U_Remarks, U_Attachment, U_TripTicketNo, U_WaybillNo, U_ShipmentManifestNo, U_DeliveryReceiptNo, U_SeriesNo, U_ActualPaymentDate, U_PaymentReference, 
    U_PaymentStatus
--COLUMNS
FROM TP_EXTRACT  WITH (NOLOCK) 