SELECT 
--COLUMNS
    X.DisableTableRow, X.U_BookingNumber, X.DisableSomeFields, X.Code, X.U_BookingId, X.U_BookingDate, X.U_PODNum, X.U_PODSONum, X.U_ClientName, X.U_TruckerName, X.U_TruckerSAP, X.U_PlateNumber, X.U_VehicleTypeCap, X.U_ISLAND, X.U_ISLAND_D, 
    X.U_IFINTERISLAND, X.U_DeliveryStatus, X.U_DeliveryDatePOD, X.U_NoOfDrops, X.U_TripType, X.U_Receivedby, X.U_ClientReceivedDate, X.U_ActualDateRec_Intitial, X.U_ActualHCRecDate, X.U_DateReturned, X.U_PODinCharge, X.U_VerifiedDateHC, 
    X.U_TPStatus, X.U_Aging, X.U_GrossTruckerRates, X.U_RateBasis, X.U_GrossTruckerRatesN, X.U_TaxType, X.U_Demurrage, X.U_AddtlDrop, X.U_BoomTruck, X.U_BoomTruck2, X.U_Manpower, X.U_BackLoad, X.U_Addtlcharges, X.U_DemurrageN, 
    X.U_AddtlChargesN, X.U_ActualRates, X.U_RateAdjustments, X.U_ActualDemurrage, X.U_ActualCharges, X.U_OtherCharges, X.WaivedDaysx, X.U_ClientSubOverdue, X.U_ClientPenaltyCalc, X.xHolidayOrWeekend, X.U_InteluckPenaltyCalc, 
    X.U_InitialHCRecDate, X.U_DeliveryDateDTR, X.U_TotalInitialTruckers, X.U_LostPenaltyCalc, X.U_TotalSubPenalty, X.U_TotalPenaltyWaived, X.U_TotalPenalty, X.U_TotalPayable, X.U_EWT2307, X.U_TotalPayableRec, X.U_PVNo, X.U_ORRefNo, X.U_TPincharge, 
    X.U_CAandDP, X.U_Interest, X.U_OtherDeductions, X.U_TOTALDEDUCTIONS, X.U_REMARKS1, X.U_TotalAP, X.U_VarTP, X.U_APInvLineNum, X.U_PercPenaltyCharge, X.U_DocNum, X.U_Paid, X.U_OtherPODDoc, X.U_DeliveryOrigin, X.U_Remarks2, 
    X.U_RemarksPOD, X.U_GroupProject, X.U_Destination, X.U_Remarks, X.U_Attachment, X.U_TripTicketNo, X.U_WaybillNo, X.U_ShipmentManifestNo, X.U_DeliveryReceiptNo, X.U_SeriesNo, X.U_ActualPaymentDate, X.U_PaymentReference, 
    X.U_PaymentStatus
--COLUMNS
FROM TP_EXTRACT X  WITH (NOLOCK) 