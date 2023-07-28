SELECT 
--COLUMNS
    U_BookingNumber, DisableTableRow, DisableSomeFields, Code, U_BookingId, U_BookingDate, U_PODNum, U_PODSONum, U_CustomerName, U_SAPClient, U_PlateNumber, U_VehicleTypeCap, U_DeliveryStatus, U_DeliveryDatePOD,
    U_NoOfDrops, U_TripType, U_ClientReceivedDate, U_ActualHCRecDate, U_PODinCharge, U_VerifiedDateHC, U_PTFNo, U_DateForwardedBT, U_BillingDeadline, U_BillingStatus, U_BillingTeam, U_GrossInitialRate, U_Demurrage,
    U_AddCharges, U_ActualBilledRate, U_RateAdjustments, U_ActualDemurrage, U_ActualAddCharges, U_TotalRecClients, U_CheckingTotalBilled, U_Checking, U_CWT2307, U_SOBNumber, U_ForwardLoad, U_BackLoad,
    U_TypeOfAccessorial, U_TimeInEmptyDem, U_TimeOutEmptyDem, U_VerifiedEmptyDem, U_TimeInLoadedDem, U_TimeOutLoadedDem, U_VerifiedLoadedDem, U_TimeInAdvLoading, U_DayOfTheWeek, U_TimeIn, U_TimeOut,
    U_TotalExceed, U_ODOIn, U_ODOOut, U_TotalUsage, U_SOLineNum, U_ARInvLineNum, ExtraDays, U_TotalAR, U_VarAR, U_ServiceType, U_DocNum, U_InvoiceNo, U_DeliveryReceiptNo, U_SeriesNo, U_GroupProject, U_DeliveryOrigin,
    U_Destination, U_OtherPODDoc, U_RemarksPOD, U_PODStatusDetail, U_BTRemarks, U_DestinationClient, U_Remarks, U_Attachment, U_SI_DRNo, U_TripTicketNo, U_WaybillNo, U_ShipmentManifestNo, U_OutletNo, U_CBM,
    U_DeliveryMode, U_SourceWhse, U_SONo, U_NameCustomer, U_CategoryDR, U_IDNumber, U_Status, U_TotalInvAmount
--COLUMNS
FROM BILLING_EXTRACT WITH (NOLOCK) 