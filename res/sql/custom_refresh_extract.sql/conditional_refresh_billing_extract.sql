PRINT 'BEFORE TRY'
BEGIN TRY
    BEGIN TRAN
    PRINT 'First Statement in the TRY block'
    
	DROP TABLE IF EXISTS TMP_CON_BILLING_EXTRACT_$serial
	SELECT
    U_BookingNumber
INTO TMP_CON_BILLING_EXTRACT_$serial
FROM [@PCTP_POD] WITH (NOLOCK)
WHERE U_PTFNo = 'PTF2023-2208'

	DROP TABLE IF EXISTS TMP_INSERT_CON_BILLING_EXTRACT_$serial
SELECT
    --COLUMNS
    T0.U_BookingId AS U_BookingNumber ,
    CASE
        WHEN (SELECT DISTINCT COUNT(*)
    FROM OINV H LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
    WHERE L.ItemCode = T0.U_BookingId AND H.CANCELED = 'N') > 1
        THEN 'Y'
        ELSE 'N'
    END AS DisableTableRow,
    CASE
        WHEN (SELECT DISTINCT COUNT(*)
    FROM OINV H LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
    WHERE L.ItemCode = T0.U_BookingId AND H.CANCELED = 'N') = 1
        THEN 'DisableSomeFields'
        ELSE ''
    END AS DisableSomeFields,
    T0.Code,
    T0.U_BookingId,
    pod.U_BookingDate,
    -- T0.U_PODNum,
    T0.U_BookingId AS U_PODNum,
    (
        SELECT TOP 1
        header.DocNum
    FROM ORDR header
        LEFT JOIN RDR1 line ON line.DocEntry = header.DocEntry
    WHERE line.ItemCode = T0.U_BookingId
        AND header.CANCELED = 'N'
    ) AS U_PODSONum,
    T2.CardName AS U_CustomerName,
    pod.U_SAPClient AS U_SAPClient,
    T0.U_PlateNumber,
    pod.U_VehicleTypeCap,
    pod.U_DeliveryStatus,
    pod.U_DeliveryDatePOD,
    pod.U_NoOfDrops,
    pod.U_TripType AS U_TripType,
    pod.U_ClientReceivedDate,
    pod.U_ActualHCRecDate,
    pod.U_PODinCharge AS U_PODinCharge,
    pod.U_VerifiedDateHC,
    pod.U_PTFNo,
    T0.U_DateForwardedBT,
    T0.U_BillingDeadline,
    -- T0.U_BillingStatus,
    (
        SELECT TOP 1
        CASE 
                WHEN EXISTS (
                    SELECT Code
        FROM [@BILLINGSTATUS]
        WHERE Code = header.U_BillingStatus
                ) THEN header.U_BillingStatus
                ELSE NULL 
            END
    FROM OINV header
        LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
    WHERE line.ItemCode = T0.U_BookingId
        AND header.CANCELED = 'N'
        AND header.U_BillingStatus IS NOT NULL
    ) AS U_BillingStatus,
    -- CASE WHEN ARHeader.U_BillingStatus IS NOT NULL THEN ARHeader.U_BillingStatus
    -- ELSE T0.U_BillingStatus END AS U_BillingStatus,
    T0.U_BillingTeam,
    pricing.U_GrossClientRates AS U_GrossInitialRate,
    pricing.U_Demurrage AS U_Demurrage,

    ISNULL(pricing.U_AddtlDrop,0) + 
ISNULL(pricing.U_BoomTruck,0) + 
ISNULL(pricing.U_Manpower,0) + 
ISNULL(pricing.U_Backload,0)  AS U_AddCharges,


    T0.U_ActualBilledRate,
    T0.U_RateAdjustments,
    T0.U_ActualDemurrage,
    T0.U_ActualAddCharges,
    T0.U_TotalRecClients,
    T0.U_CheckingTotalBilled,
    T0.U_Checking,
    T0.U_CWT2307,
    pod.U_SOBNumber AS U_SOBNumber,
    pod.U_ForwardLoad AS U_ForwardLoad,
    pod.U_BackLoad AS U_BackLoad,
    pod.U_TypeOfAccessorial AS U_TypeOfAccessorial,
    pod.U_TimeInEmptyDem AS U_TimeInEmptyDem,
    pod.U_TimeOutEmptyDem AS U_TimeOutEmptyDem,
    pod.U_VerifiedEmptyDem AS U_VerifiedEmptyDem,
    pod.U_TimeInLoadedDem AS U_TimeInLoadedDem,
    pod.U_TimeOutLoadedDem AS U_TimeOutLoadedDem,
    pod.U_VerifiedLoadedDem AS U_VerifiedLoadedDem,
    pod.U_TimeInAdvLoading AS U_TimeInAdvLoading,
    pod.U_DayOfTheWeek AS U_DayOfTheWeek,
    pod.U_TimeIn AS U_TimeIn,
    pod.U_TimeOut AS U_TimeOut,
    pod.U_TotalNoExceed AS U_TotalExceed,
    pod.U_ODOIn AS U_ODOIn,
    pod.U_ODOOut AS U_ODOOut,
    pod.U_TotalUsage AS U_TotalUsage,
    T0.U_SOLineNum,
    T0.U_ARInvLineNum,
    T4.ExtraDays,
    (SELECT
        SUM(L.PriceAfVAT)
    FROM OINV H
        LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
    WHERE H.CANCELED = 'N' AND L.ItemCode = T0.U_BookingId) AS U_TotalAR,
    (SELECT
        SUM(L.PriceAfVAT)
    FROM OINV H
        LEFT JOIN INV1 L ON H.DocEntry = L.DocEntry
    WHERE H.CANCELED = 'N' AND L.ItemCode = T0.U_BookingId) - T0.U_TotalRecClients AS U_VarAR,
    CAST((
        SELECT DISTINCT
        SUBSTRING(
                (
                    SELECT CONCAT(', ', header.U_ServiceType)  AS [text()]
        FROM INV1 line
            LEFT JOIN OINV header ON header.DocEntry = line.DocEntry
        WHERE line.ItemCode = T0.U_BookingId
            AND header.U_ServiceType IS NOT NULL
            AND header.CANCELED = 'N'
        FOR XML PATH (''), TYPE
                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
    FROM OINV header
        LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
    WHERE line.ItemCode = T0.U_BookingId
        AND header.U_ServiceType IS NOT NULL
        AND header.CANCELED = 'N'
        ) as nvarchar(max)
    ) AS U_ServiceType,
    CAST((
        SELECT DISTINCT
        SUBSTRING(
                (
                    SELECT CONCAT(', ', header.DocNum)  AS [text()]
        FROM INV1 line
            LEFT JOIN OINV header ON header.DocEntry = line.DocEntry
        WHERE line.ItemCode = T0.U_BookingId
            AND header.CANCELED = 'N'
        FOR XML PATH (''), TYPE
                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
    FROM OINV header
        LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
    WHERE line.ItemCode = T0.U_BookingId
        AND header.CANCELED = 'N') as nvarchar(max)
    ) AS U_DocNum,
    CAST((
        SELECT DISTINCT
        SUBSTRING(
                (
                    SELECT
            CASE
                        WHEN header.U_InvoiceNo = '' OR header.U_InvoiceNo IS NULL THEN ''
                        ELSE CONCAT(', ', header.U_InvoiceNo)
                    END AS [text()]
        FROM INV1 line
            LEFT JOIN OINV header ON header.DocEntry = line.DocEntry
        WHERE line.ItemCode = T0.U_BookingId
            AND header.CANCELED = 'N'
        FOR XML PATH (''), TYPE
                ).value('text()[1]','nvarchar(max)'), 2, 1000) DocEntry
    FROM OINV header
        LEFT JOIN INV1 line ON line.DocEntry = header.DocEntry
    WHERE line.ItemCode = T0.U_BookingId
        AND header.CANCELED = 'N') as nvarchar(max)
    ) AS U_InvoiceNo,

    CAST(pod.U_DeliveryReceiptNo as nvarchar(max)) AS U_DeliveryReceiptNo,
    CAST(pod.U_SeriesNo as nvarchar(max)) AS U_SeriesNo,
    ISNULL(CAST(T2.U_GroupLocation as nvarchar(max)), T0.U_GroupProject) AS U_GroupProject,
    CAST(pod.U_DeliveryOrigin as nvarchar(max)) AS U_DeliveryOrigin,
    CAST(pod.U_Destination as nvarchar(max)) AS U_Destination,
    CAST(pod.U_OtherPODDoc as nvarchar(max)) AS U_OtherPODDoc,
    CAST(pod.U_RemarksPOD as nvarchar(max)) AS U_RemarksPOD,
    CAST(pod.U_PODStatusDetail as nvarchar(max)) AS U_PODStatusDetail,
    CAST(T0.U_BTRemarks as nvarchar(max)) AS U_BTRemarks,
    CAST(pod.U_DestinationClient as nvarchar(max)) AS U_DestinationClient,
    CAST(pod.U_Remarks as nvarchar(max)) AS U_Remarks,
    CAST(pod.U_Attachment as nvarchar(max)) AS U_Attachment,
    CAST(pod.U_SI_DRNo as nvarchar(max)) AS U_SI_DRNo,
    CAST(pod.U_TripTicketNo as nvarchar(max)) AS U_TripTicketNo,
    CAST(pod.U_WaybillNo as nvarchar(max)) AS U_WaybillNo,
    CAST(pod.U_ShipmentNo as nvarchar(max)) AS U_ShipmentManifestNo,
    CAST(pod.U_OutletNo as nvarchar(max)) AS U_OutletNo,
    CAST(pod.U_CBM as nvarchar(max)) AS U_CBM,
    CAST(pod.U_DeliveryMode as nvarchar(max)) AS U_DeliveryMode,
    CAST(pod.U_SourceWhse as nvarchar(max)) AS U_SourceWhse,
    CAST(pod.U_SONo as nvarchar(max)) AS U_SONo,
    CAST(pod.U_NameCustomer as nvarchar(max)) AS U_NameCustomer,
    CAST(pod.U_CategoryDR as nvarchar(max)) AS U_CategoryDR,
    CAST(pod.U_IDNumber as nvarchar(max)) AS U_IDNumber,
    CAST(pod.U_ApprovalStatus as nvarchar(max)) AS U_Status,
    CAST(pod.U_TotalInvAmount as nvarchar(max)) AS U_TotalInvAmount

--COLUMNS

INTO TMP_INSERT_CON_BILLING_EXTRACT_$serial

FROM [dbo].[@PCTP_BILLING] T0  WITH (NOLOCK)
    INNER JOIN [dbo].[@PCTP_POD] pod ON T0.U_BookingId = pod.U_BookingNumber
        AND (CAST(pod.U_PODStatusDetail as nvarchar(max)) LIKE '%Verified%' OR CAST(pod.U_PODStatusDetail as nvarchar(max)) LIKE '%ForAdvanceBilling%')
    --JOINS
    LEFT JOIN OCRD T2 ON pod.U_SAPClient = T2.CardCode
    LEFT JOIN [dbo].[@PCTP_PRICING] pricing ON T0.U_BookingId = pricing.U_BookingId
    LEFT JOIN OCTG T4 ON T2.GroupNum = T4.GroupNum
    -- LEFT JOIN (SELECT DocEntry, MIN(ItemCode) AS ItemCode
    -- FROM INV1
    -- GROUP BY DocEntry, ItemCode) ARLine ON ARLine.ItemCode = T0.U_BookingId
    -- LEFT JOIN (SELECT DocEntry, MIN(U_BillingStatus) AS U_BillingStatus, MIN(DocNum) AS DocNum
    -- FROM OINV
    -- GROUP BY DocEntry) ARHeader ON ARHeader.DocEntry = ARLine.DocEntry
    LEFT JOIN TP_FORMULA TF ON TF.U_BookingId = T0.U_BookingId
--JOINS
WHERE T0.U_BookingId IN (SELECT U_BookingNumber
FROM TMP_CON_BILLING_EXTRACT_$serial WITH (NOLOCK))

DELETE FROM BILLING_EXTRACT WHERE U_BookingNumber IN (SELECT U_BookingNumber
FROM TMP_CON_BILLING_EXTRACT_$serial WITH (NOLOCK))

INSERT INTO BILLING_EXTRACT
SELECT
    *
FROM TMP_INSERT_CON_BILLING_EXTRACT_$serial

DROP TABLE IF EXISTS TMP_INSERT_CON_BILLING_EXTRACT_$serial
DROP TABLE IF EXISTS TMP_CON_BILLING_EXTRACT_$serial

    PRINT 'Last Statement in the TRY block'
    COMMIT TRAN
END TRY
BEGIN CATCH
    PRINT 'In CATCH Block'
    IF(@@TRANCOUNT > 0)
        ROLLBACK TRAN;

    THROW; -- raise error to the client
END CATCH
PRINT 'After END CATCH'