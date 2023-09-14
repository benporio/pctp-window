SELECT 
  CASE WHEN (
    (SELECT value FROM @DocNum WHERE id = T0.U_BookingId) LIKE '%[0-9]%'
    OR (SELECT value FROM @Paid WHERE id = T0.U_BookingId) LIKE '%[0-9]%'
  ) THEN CASE 
  --TOTAL AP 2 PAID  ------------
  WHEN (
    (SELECT value FROM @DocNum WHERE id = T0.U_BookingId) NOT LIKE '%[0-9]%'
    OR (SELECT value FROM @Paid WHERE id = T0.U_BookingId) LIKE '%[0-9]%'
  ) THEN ISNULL(
    (
      SELECT 
        DISTINCT (
          CASE WHEN T5.U_Rates LIKE '%U_GrossTruckerRates%' THEN CASE WHEN ISNULL(truckersub.VatStatus, 'Y') = 'Y' THEN pricingsub.U_GrossTruckerRates WHEN ISNULL(truckersub.VatStatus, 'Y') = 'N' THEN (
            pricingsub.U_GrossTruckerRates / 1.12
          ) END ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_ActualRates%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_ActualRates AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_RateAdjustments%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_RateAdjustments AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_DemurrageN%' THEN CASE WHEN ISNULL(truckersub.VatStatus, 'Y') = 'Y' THEN pricingsub.U_Demurrage2 WHEN ISNULL(truckersub.VatStatus, 'Y') = 'N' THEN (pricingsub.U_Demurrage2 / 1.12) END ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_totalAddtlCharges2%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_ActualCharges AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_ActualDemurrage%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_ActualDemurrage AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_ActualCharges%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_ActualCharges AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_BoomTruck2%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_BoomTruck2 AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_OtherCharges%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_OtherCharges AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END
        ) - ISNULL(tpsub.U_OtherDeductions, 0) + abs(
          dbo.computeTotalPenaltyWaived(
            dbo.computeTotalSubPenalties(
              dbo.computeClientPenaltyCalc(
                dbo.computeClientSubOverdue(
                  podsub.U_DeliveryDateDTR, 
                  podsub.U_ClientReceivedDate, 
                  ISNULL(podsub.U_WaivedDays, 0), 
                  CAST(
                    ISNULL(clientsub.U_DCD, 0) as int
                  )
                )
              ), 
              dbo.computeInteluckPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                dbo.computeOverdueDays(
                  podsub.U_ActualHCRecDate, 
                  dbo.computePODSubmitDeadline(
                    podsub.U_DeliveryDateDTR, 
                    ISNULL(clientsub.U_CDC, 0)
                  ), 
                  ISNULL(podsub.U_HolidayOrWeekend, 0)
                )
              ), 
              dbo.computeLostPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                podsub.U_InitialHCRecDate, 
                podsub.U_DeliveryDateDTR, 
                pricingsub.U_TotalInitialTruckers
              ), 
              ISNULL(podsub.U_PenaltiesManual, 0)
            ), 
            ISNULL(podsub.U_PercPenaltyCharge, 0)
          )
        ) AS TotalAmount 
      FROM 
        [@PCTP_TP] tpsub 
        INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber 
        INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode 
        INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode 
        INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId --INNER JOIN [@RATESPERPV] ratessub ON ratessub.Code = tpsub.U_PVNo
        INNER JOIN [@RATESPERPV] T5 ON T5.Code = SUBSTRING(tpsub.U_PVNo, 11, 19) 
      WHERE 
        tpsub.U_BookingId = T0.U_BookingId
    ), 
    0
  )+ ISNULL(
    (
      SELECT 
        DISTINCT (
          ISNULL(
            TRY_PARSE(ratessub.U_Amount AS FLOAT), 
            0
          )+ --ISNULL(tpsub.U_ActualRates,0) +
          ISNULL(tpsub.U_RateAdjustments, 0) + ISNULL(
            TRY_PARSE(ratessub.U_AddlAmount AS FLOAT), 
            0
          ) --+
          --ISNULL(tpsub.U_ActualDemurrage,0) +
          --ISNULL(tpsub.U_ActualCharges,0)+
          --ISNULL(NULLIF(tpsub.U_BoomTruck2,''),0) +
          --ISNULL(tpsub.U_OtherCharges,0) 
          ) - (
          ABS(
            dbo.computeTotalSubPenalties(
              dbo.computeClientPenaltyCalc(
                dbo.computeClientSubOverdue(
                  podsub.U_DeliveryDateDTR, 
                  podsub.U_ClientReceivedDate, 
                  ISNULL(podsub.U_WaivedDays, 0), 
                  CAST(
                    ISNULL(clientsub.U_DCD, 0) as int
                  )
                )
              ), 
              dbo.computeInteluckPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                dbo.computeOverdueDays(
                  podsub.U_ActualHCRecDate, 
                  dbo.computePODSubmitDeadline(
                    podsub.U_DeliveryDateDTR, 
                    ISNULL(clientsub.U_CDC, 0)
                  ), 
                  ISNULL(podsub.U_HolidayOrWeekend, 0)
                )
              ), 
              dbo.computeLostPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                podsub.U_InitialHCRecDate, 
                podsub.U_DeliveryDateDTR, 
                pricingsub.U_TotalInitialTruckers
              ), 
              ISNULL(podsub.U_PenaltiesManual, 0)
            )
          ) - dbo.computeTotalPenaltyWaived(
            dbo.computeTotalSubPenalties(
              dbo.computeClientPenaltyCalc(
                dbo.computeClientSubOverdue(
                  podsub.U_DeliveryDateDTR, 
                  podsub.U_ClientReceivedDate, 
                  ISNULL(podsub.U_WaivedDays, 0), 
                  CAST(
                    ISNULL(clientsub.U_DCD, 0) as int
                  )
                )
              ), 
              dbo.computeInteluckPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                dbo.computeOverdueDays(
                  podsub.U_ActualHCRecDate, 
                  dbo.computePODSubmitDeadline(
                    podsub.U_DeliveryDateDTR, 
                    ISNULL(clientsub.U_CDC, 0)
                  ), 
                  ISNULL(podsub.U_HolidayOrWeekend, 0)
                )
              ), 
              dbo.computeLostPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                podsub.U_InitialHCRecDate, 
                podsub.U_DeliveryDateDTR, 
                pricingsub.U_TotalInitialTruckers
              ), 
              ISNULL(podsub.U_PenaltiesManual, 0)
            ), 
            ISNULL(podsub.U_PercPenaltyCharge, 0)
          )
        ) AS TotalAmount 
      FROM 
        [@PCTP_TP] tpsub 
        INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber 
        INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode 
        INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode 
        INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId 
        LEFT JOIN [@FirstratesTP] ratessub ON ratessub.U_BN = tpsub.U_BookingId 
        AND ratessub.U_PVNo = SUBSTRING(tpsub.U_PVNo, 1, 9) 
      WHERE 
        tpsub.U_BookingId = T0.U_BookingId
    ), 
    0
  ) --TOTAL AP 1 UNPAID 1 PAID  ------------
  WHEN CAST(
    (
      SELECT 
        DISTINCT SUBSTRING(
          (
            SELECT 
              CONCAT(', ', header.DocNum) AS [text() ] 
            FROM 
              PCH1 line 
              LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry 
            WHERE 
              header.CANCELED = 'N' 
              AND header.PaidSum = 0 
              AND (
                line.ItemCode = T0.U_BookingId 
                or REPLACE(
                  REPLACE(
                    RTRIM(
                      LTRIM(T0.U_PVNo)
                    ), 
                    ' ', 
                    ''
                  ), 
                  ',', 
                  ''
                ) LIKE '%' + RTRIM(
                  LTRIM(header.U_PVNo)
                ) + '%'
              ) FOR XML PATH (''), 
              TYPE
          ).value('text()[1]', 'nvarchar(max)'), 
          2, 
          1000
        ) DocEntry 
      FROM 
        OPCH header 
        LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry 
      WHERE 
        header.CANCELED = 'N' 
        AND (
          line.ItemCode = T0.U_BookingId 
          or REPLACE(
            REPLACE(
              RTRIM(
                LTRIM(T0.U_PVNo)
              ), 
              ' ', 
              ''
            ), 
            ',', 
            ''
          ) LIKE '%' + RTRIM(
            LTRIM(header.U_PVNo)
          ) + '%'
        )
    ) as nvarchar(max)
  ) IS NOT NULL 
  AND CAST(
    (
      SELECT 
        DISTINCT SUBSTRING(
          (
            SELECT 
              CONCAT(', ', header.DocNum) AS [text() ] 
            FROM 
              PCH1 line 
              LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry 
            WHERE 
              header.CANCELED = 'N' 
              AND header.PaidSum > 0 
              AND (
                line.ItemCode = T0.U_BookingId 
                or REPLACE(
                  REPLACE(
                    RTRIM(
                      LTRIM(T0.U_PVNo)
                    ), 
                    ' ', 
                    ''
                  ), 
                  ',', 
                  ''
                ) LIKE '%' + RTRIM(
                  LTRIM(header.U_PVNo)
                ) + '%'
              ) FOR XML PATH (''), 
              TYPE
          ).value('text()[1]', 'nvarchar(max)'), 
          2, 
          1000
        ) DocEntry 
      FROM 
        OPCH header 
        LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry 
      WHERE 
        header.CANCELED = 'N' 
        AND (
          line.ItemCode = T0.U_BookingId 
          or REPLACE(
            REPLACE(
              RTRIM(
                LTRIM(T0.U_PVNo)
              ), 
              ' ', 
              ''
            ), 
            ',', 
            ''
          ) LIKE '%' + RTRIM(
            LTRIM(header.U_PVNo)
          ) + '%'
        )
    ) as nvarchar(max)
  ) IS NOT NULL THEN ISNULL(
    (
      SELECT 
        DISTINCT (
          CASE WHEN T5.U_Rates LIKE '%U_GrossTruckerRates%' THEN CASE WHEN ISNULL(truckersub.VatStatus, 'Y') = 'Y' THEN pricingsub.U_GrossTruckerRates WHEN ISNULL(truckersub.VatStatus, 'Y') = 'N' THEN (
            pricingsub.U_GrossTruckerRates / 1.12
          ) END ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_ActualRates%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_ActualRates AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_RateAdjustments%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_RateAdjustments AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_DemurrageN%' THEN CASE WHEN ISNULL(truckersub.VatStatus, 'Y') = 'Y' THEN pricingsub.U_Demurrage2 WHEN ISNULL(truckersub.VatStatus, 'Y') = 'N' THEN (pricingsub.U_Demurrage2 / 1.12) END ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_totalAddtlCharges2%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_ActualCharges AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_ActualDemurrage%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_ActualDemurrage AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_ActualCharges%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_ActualCharges AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_BoomTruck2%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_BoomTruck2 AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_OtherCharges%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_OtherCharges AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END
        ) - ISNULL(tpsub.U_OtherDeductions, 0) + abs(
          dbo.computeTotalPenaltyWaived(
            dbo.computeTotalSubPenalties(
              dbo.computeClientPenaltyCalc(
                dbo.computeClientSubOverdue(
                  podsub.U_DeliveryDateDTR, 
                  podsub.U_ClientReceivedDate, 
                  ISNULL(podsub.U_WaivedDays, 0), 
                  CAST(
                    ISNULL(clientsub.U_DCD, 0) as int
                  )
                )
              ), 
              dbo.computeInteluckPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                dbo.computeOverdueDays(
                  podsub.U_ActualHCRecDate, 
                  dbo.computePODSubmitDeadline(
                    podsub.U_DeliveryDateDTR, 
                    ISNULL(clientsub.U_CDC, 0)
                  ), 
                  ISNULL(podsub.U_HolidayOrWeekend, 0)
                )
              ), 
              dbo.computeLostPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                podsub.U_InitialHCRecDate, 
                podsub.U_DeliveryDateDTR, 
                pricingsub.U_TotalInitialTruckers
              ), 
              ISNULL(podsub.U_PenaltiesManual, 0)
            ), 
            ISNULL(podsub.U_PercPenaltyCharge, 0)
          )
        ) AS TotalAmount 
      FROM 
        [@PCTP_TP] tpsub 
        INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber 
        INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode 
        INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode 
        INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId --INNER JOIN [@RATESPERPV] ratessub ON ratessub.Code = tpsub.U_PVNo
        INNER JOIN [@RATESPERPV] T5 ON T5.Code = SUBSTRING(tpsub.U_PVNo, 11, 19) 
      WHERE 
        tpsub.U_BookingId = T0.U_BookingId
    ), 
    0
  )+ ISNULL(
    (
      SELECT 
        DISTINCT (
          ISNULL(
            TRY_PARSE(ratessub.U_Amount AS FLOAT), 
            0
          )+ --ISNULL(tpsub.U_ActualRates,0) +
          ISNULL(tpsub.U_RateAdjustments, 0) + ISNULL(
            TRY_PARSE(ratessub.U_AddlAmount AS FLOAT), 
            0
          ) --+
          --ISNULL(tpsub.U_ActualDemurrage,0) +
          --ISNULL(tpsub.U_ActualCharges,0)+
          --ISNULL(NULLIF(tpsub.U_BoomTruck2,''),0) +
          --ISNULL(tpsub.U_OtherCharges,0) 
          ) - (
          ABS(
            dbo.computeTotalSubPenalties(
              dbo.computeClientPenaltyCalc(
                dbo.computeClientSubOverdue(
                  podsub.U_DeliveryDateDTR, 
                  podsub.U_ClientReceivedDate, 
                  ISNULL(podsub.U_WaivedDays, 0), 
                  CAST(
                    ISNULL(clientsub.U_DCD, 0) as int
                  )
                )
              ), 
              dbo.computeInteluckPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                dbo.computeOverdueDays(
                  podsub.U_ActualHCRecDate, 
                  dbo.computePODSubmitDeadline(
                    podsub.U_DeliveryDateDTR, 
                    ISNULL(clientsub.U_CDC, 0)
                  ), 
                  ISNULL(podsub.U_HolidayOrWeekend, 0)
                )
              ), 
              dbo.computeLostPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                podsub.U_InitialHCRecDate, 
                podsub.U_DeliveryDateDTR, 
                pricingsub.U_TotalInitialTruckers
              ), 
              ISNULL(podsub.U_PenaltiesManual, 0)
            )
          ) - dbo.computeTotalPenaltyWaived(
            dbo.computeTotalSubPenalties(
              dbo.computeClientPenaltyCalc(
                dbo.computeClientSubOverdue(
                  podsub.U_DeliveryDateDTR, 
                  podsub.U_ClientReceivedDate, 
                  ISNULL(podsub.U_WaivedDays, 0), 
                  CAST(
                    ISNULL(clientsub.U_DCD, 0) as int
                  )
                )
              ), 
              dbo.computeInteluckPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                dbo.computeOverdueDays(
                  podsub.U_ActualHCRecDate, 
                  dbo.computePODSubmitDeadline(
                    podsub.U_DeliveryDateDTR, 
                    ISNULL(clientsub.U_CDC, 0)
                  ), 
                  ISNULL(podsub.U_HolidayOrWeekend, 0)
                )
              ), 
              dbo.computeLostPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                podsub.U_InitialHCRecDate, 
                podsub.U_DeliveryDateDTR, 
                pricingsub.U_TotalInitialTruckers
              ), 
              ISNULL(podsub.U_PenaltiesManual, 0)
            ), 
            ISNULL(podsub.U_PercPenaltyCharge, 0)
          )
        ) AS TotalAmount 
      FROM 
        [@PCTP_TP] tpsub 
        INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber 
        INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode 
        INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode 
        INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId 
        LEFT JOIN [@FirstratesTP] ratessub ON ratessub.U_BN = tpsub.U_BookingId 
        AND ratessub.U_PVNo = SUBSTRING(tpsub.U_PVNo, 1, 9) 
      WHERE 
        tpsub.U_BookingId = T0.U_BookingId
    ), 
    0
  ) --TOTAL AP 2 UNPAID  ------------
  WHEN CHARINDEX(
    ',', 
    CAST(
      (
        SELECT 
          DISTINCT SUBSTRING(
            (
              SELECT 
                CONCAT(', ', header.DocNum) AS [text() ] 
              FROM 
                PCH1 line 
                LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry 
              WHERE 
                header.CANCELED = 'N' 
                AND header.PaidSum = 0 
                AND (
                  line.ItemCode = T0.U_BookingId 
                  or REPLACE(
                    REPLACE(
                      RTRIM(
                        LTRIM(T0.U_PVNo)
                      ), 
                      ' ', 
                      ''
                    ), 
                    ',', 
                    ''
                  ) LIKE '%' + RTRIM(
                    LTRIM(header.U_PVNo)
                  ) + '%'
                ) FOR XML PATH (''), 
                TYPE
            ).value('text()[1]', 'nvarchar(max)'), 
            2, 
            1000
          ) DocEntry 
        FROM 
          OPCH header 
          LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry 
        WHERE 
          header.CANCELED = 'N' 
          AND (
            line.ItemCode = T0.U_BookingId 
            or REPLACE(
              REPLACE(
                RTRIM(
                  LTRIM(T0.U_PVNo)
                ), 
                ' ', 
                ''
              ), 
              ',', 
              ''
            ) LIKE '%' + RTRIM(
              LTRIM(header.U_PVNo)
            ) + '%'
          )
      ) as nvarchar(max)
    )
  ) > 0 
  AND CAST(
    (
      SELECT 
        DISTINCT SUBSTRING(
          (
            SELECT 
              CONCAT(', ', header.DocNum) AS [text() ] 
            FROM 
              PCH1 line 
              LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry 
            WHERE 
              header.CANCELED = 'N' 
              AND header.PaidSum > 0 
              AND (
                line.ItemCode = T0.U_BookingId 
                or REPLACE(
                  REPLACE(
                    RTRIM(
                      LTRIM(T0.U_PVNo)
                    ), 
                    ' ', 
                    ''
                  ), 
                  ',', 
                  ''
                ) LIKE '%' + RTRIM(
                  LTRIM(header.U_PVNo)
                ) + '%'
              ) FOR XML PATH (''), 
              TYPE
          ).value('text()[1]', 'nvarchar(max)'), 
          2, 
          1000
        ) DocEntry 
      FROM 
        OPCH header 
        LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry 
      WHERE 
        header.CANCELED = 'N' 
        AND (
          line.ItemCode = T0.U_BookingId 
          or REPLACE(
            REPLACE(
              RTRIM(
                LTRIM(T0.U_PVNo)
              ), 
              ' ', 
              ''
            ), 
            ',', 
            ''
          ) LIKE '%' + RTRIM(
            LTRIM(header.U_PVNo)
          ) + '%'
        )
    ) as nvarchar(max)
  ) IS NULL THEN ISNULL(
    (
      SELECT 
        DISTINCT (
          CASE WHEN T5.U_Rates LIKE '%U_GrossTruckerRates%' THEN CASE WHEN ISNULL(truckersub.VatStatus, 'Y') = 'Y' THEN pricingsub.U_GrossTruckerRates WHEN ISNULL(truckersub.VatStatus, 'Y') = 'N' THEN (
            pricingsub.U_GrossTruckerRates / 1.12
          ) END ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_ActualRates%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_ActualRates AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_RateAdjustments%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_RateAdjustments AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_DemurrageN%' THEN CASE WHEN ISNULL(truckersub.VatStatus, 'Y') = 'Y' THEN pricingsub.U_Demurrage2 WHEN ISNULL(truckersub.VatStatus, 'Y') = 'N' THEN (pricingsub.U_Demurrage2 / 1.12) END ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_totalAddtlCharges2%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_ActualCharges AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_ActualDemurrage%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_ActualDemurrage AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_ActualCharges%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_ActualCharges AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_BoomTruck2%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_BoomTruck2 AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END + CASE WHEN T5.U_Rates LIKE '%U_OtherCharges%' THEN ISNULL(
            NULLIF(
              CAST(tpsub.U_OtherCharges AS FLOAT), 
              ''
            ), 
            0
          ) ELSE 0.00 END
        ) - ISNULL(tpsub.U_OtherDeductions, 0) + abs(
          dbo.computeTotalPenaltyWaived(
            dbo.computeTotalSubPenalties(
              dbo.computeClientPenaltyCalc(
                dbo.computeClientSubOverdue(
                  podsub.U_DeliveryDateDTR, 
                  podsub.U_ClientReceivedDate, 
                  ISNULL(podsub.U_WaivedDays, 0), 
                  CAST(
                    ISNULL(clientsub.U_DCD, 0) as int
                  )
                )
              ), 
              dbo.computeInteluckPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                dbo.computeOverdueDays(
                  podsub.U_ActualHCRecDate, 
                  dbo.computePODSubmitDeadline(
                    podsub.U_DeliveryDateDTR, 
                    ISNULL(clientsub.U_CDC, 0)
                  ), 
                  ISNULL(podsub.U_HolidayOrWeekend, 0)
                )
              ), 
              dbo.computeLostPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                podsub.U_InitialHCRecDate, 
                podsub.U_DeliveryDateDTR, 
                pricingsub.U_TotalInitialTruckers
              ), 
              ISNULL(podsub.U_PenaltiesManual, 0)
            ), 
            ISNULL(podsub.U_PercPenaltyCharge, 0)
          )
        ) AS TotalAmount 
      FROM 
        [@PCTP_TP] tpsub 
        INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber 
        INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode 
        INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode 
        INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId --INNER JOIN [@RATESPERPV] ratessub ON ratessub.Code = tpsub.U_PVNo
        INNER JOIN [@RATESPERPV] T5 ON T5.Code = SUBSTRING(tpsub.U_PVNo, 11, 19) 
      WHERE 
        tpsub.U_BookingId = T0.U_BookingId
    ), 
    0
  )+ ISNULL(
    (
      SELECT 
        DISTINCT (
          ISNULL(
            TRY_PARSE(ratessub.U_Amount AS FLOAT), 
            0
          )+ --ISNULL(tpsub.U_ActualRates,0) +
          ISNULL(tpsub.U_RateAdjustments, 0) + ISNULL(
            TRY_PARSE(ratessub.U_AddlAmount AS FLOAT), 
            0
          ) --+
          --ISNULL(tpsub.U_ActualDemurrage,0) +
          --ISNULL(tpsub.U_ActualCharges,0)+
          --ISNULL(NULLIF(tpsub.U_BoomTruck2,''),0) +
          --ISNULL(tpsub.U_OtherCharges,0) 
          ) - (
          ABS(
            dbo.computeTotalSubPenalties(
              dbo.computeClientPenaltyCalc(
                dbo.computeClientSubOverdue(
                  podsub.U_DeliveryDateDTR, 
                  podsub.U_ClientReceivedDate, 
                  ISNULL(podsub.U_WaivedDays, 0), 
                  CAST(
                    ISNULL(clientsub.U_DCD, 0) as int
                  )
                )
              ), 
              dbo.computeInteluckPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                dbo.computeOverdueDays(
                  podsub.U_ActualHCRecDate, 
                  dbo.computePODSubmitDeadline(
                    podsub.U_DeliveryDateDTR, 
                    ISNULL(clientsub.U_CDC, 0)
                  ), 
                  ISNULL(podsub.U_HolidayOrWeekend, 0)
                )
              ), 
              dbo.computeLostPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                podsub.U_InitialHCRecDate, 
                podsub.U_DeliveryDateDTR, 
                pricingsub.U_TotalInitialTruckers
              ), 
              ISNULL(podsub.U_PenaltiesManual, 0)
            )
          ) - dbo.computeTotalPenaltyWaived(
            dbo.computeTotalSubPenalties(
              dbo.computeClientPenaltyCalc(
                dbo.computeClientSubOverdue(
                  podsub.U_DeliveryDateDTR, 
                  podsub.U_ClientReceivedDate, 
                  ISNULL(podsub.U_WaivedDays, 0), 
                  CAST(
                    ISNULL(clientsub.U_DCD, 0) as int
                  )
                )
              ), 
              dbo.computeInteluckPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                dbo.computeOverdueDays(
                  podsub.U_ActualHCRecDate, 
                  dbo.computePODSubmitDeadline(
                    podsub.U_DeliveryDateDTR, 
                    ISNULL(clientsub.U_CDC, 0)
                  ), 
                  ISNULL(podsub.U_HolidayOrWeekend, 0)
                )
              ), 
              dbo.computeLostPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                podsub.U_InitialHCRecDate, 
                podsub.U_DeliveryDateDTR, 
                pricingsub.U_TotalInitialTruckers
              ), 
              ISNULL(podsub.U_PenaltiesManual, 0)
            ), 
            ISNULL(podsub.U_PercPenaltyCharge, 0)
          )
        ) AS TotalAmount 
      FROM 
        [@PCTP_TP] tpsub 
        INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber 
        INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode 
        INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode 
        INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId 
        LEFT JOIN [@FirstratesTP] ratessub ON ratessub.U_BN = tpsub.U_BookingId 
        AND ratessub.U_PVNo = SUBSTRING(tpsub.U_PVNo, 1, 9) 
      WHERE 
        tpsub.U_BookingId = T0.U_BookingId
    ), 
    0
  ) --TOTAL AP 1 PAID  NO UNPAID------------
  WHEN CAST(
    (
      SELECT 
        DISTINCT SUBSTRING(
          (
            SELECT 
              CONCAT(', ', header.DocNum) AS [text() ] 
            FROM 
              PCH1 line 
              LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry 
            WHERE 
              header.CANCELED = 'N' 
              AND header.PaidSum = 0 
              AND (
                line.ItemCode = T0.U_BookingId 
                or REPLACE(
                  REPLACE(
                    RTRIM(
                      LTRIM(T0.U_PVNo)
                    ), 
                    ' ', 
                    ''
                  ), 
                  ',', 
                  ''
                ) LIKE '%' + RTRIM(
                  LTRIM(header.U_PVNo)
                ) + '%'
              ) FOR XML PATH (''), 
              TYPE
          ).value('text()[1]', 'nvarchar(max)'), 
          2, 
          1000
        ) DocEntry 
      FROM 
        OPCH header 
        LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry 
      WHERE 
        header.CANCELED = 'N' 
        AND (
          line.ItemCode = T0.U_BookingId 
          or REPLACE(
            REPLACE(
              RTRIM(
                LTRIM(T0.U_PVNo)
              ), 
              ' ', 
              ''
            ), 
            ',', 
            ''
          ) LIKE '%' + RTRIM(
            LTRIM(header.U_PVNo)
          ) + '%'
        )
    ) as nvarchar(max)
  ) IS NULL 
  AND CAST(
    (
      SELECT 
        DISTINCT SUBSTRING(
          (
            SELECT 
              CONCAT(', ', header.DocNum) AS [text() ] 
            FROM 
              PCH1 line 
              LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry 
            WHERE 
              header.CANCELED = 'N' 
              AND header.PaidSum > 0 
              AND (
                line.ItemCode = T0.U_BookingId 
                or REPLACE(
                  REPLACE(
                    RTRIM(
                      LTRIM(T0.U_PVNo)
                    ), 
                    ' ', 
                    ''
                  ), 
                  ',', 
                  ''
                ) LIKE '%' + RTRIM(
                  LTRIM(header.U_PVNo)
                ) + '%'
              ) FOR XML PATH (''), 
              TYPE
          ).value('text()[1]', 'nvarchar(max)'), 
          2, 
          1000
        ) DocEntry 
      FROM 
        OPCH header 
        LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry 
      WHERE 
        header.CANCELED = 'N' 
        AND (
          line.ItemCode = T0.U_BookingId 
          or REPLACE(
            REPLACE(
              RTRIM(
                LTRIM(T0.U_PVNo)
              ), 
              ' ', 
              ''
            ), 
            ',', 
            ''
          ) LIKE '%' + RTRIM(
            LTRIM(header.U_PVNo)
          ) + '%'
        )
    ) as nvarchar(max)
  ) IS NOT NULL THEN ISNULL(
    (
      SELECT 
        DISTINCT (
          ISNULL(
            TRY_PARSE(ratessub.U_Amount AS FLOAT), 
            0
          )+ --ISNULL(tpsub.U_ActualRates,0) +
          ISNULL(tpsub.U_RateAdjustments, 0) + ISNULL(
            TRY_PARSE(ratessub.U_AddlAmount AS FLOAT), 
            0
          ) --+
          --ISNULL(tpsub.U_ActualDemurrage,0) +
          --ISNULL(tpsub.U_ActualCharges,0)+
          --ISNULL(NULLIF(tpsub.U_BoomTruck2,''),0) +
          --ISNULL(tpsub.U_OtherCharges,0) 
          ) - (
          ABS(
            dbo.computeTotalSubPenalties(
              dbo.computeClientPenaltyCalc(
                dbo.computeClientSubOverdue(
                  podsub.U_DeliveryDateDTR, 
                  podsub.U_ClientReceivedDate, 
                  ISNULL(podsub.U_WaivedDays, 0), 
                  CAST(
                    ISNULL(clientsub.U_DCD, 0) as int
                  )
                )
              ), 
              dbo.computeInteluckPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                dbo.computeOverdueDays(
                  podsub.U_ActualHCRecDate, 
                  dbo.computePODSubmitDeadline(
                    podsub.U_DeliveryDateDTR, 
                    ISNULL(clientsub.U_CDC, 0)
                  ), 
                  ISNULL(podsub.U_HolidayOrWeekend, 0)
                )
              ), 
              dbo.computeLostPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                podsub.U_InitialHCRecDate, 
                podsub.U_DeliveryDateDTR, 
                pricingsub.U_TotalInitialTruckers
              ), 
              ISNULL(podsub.U_PenaltiesManual, 0)
            )
          ) - dbo.computeTotalPenaltyWaived(
            dbo.computeTotalSubPenalties(
              dbo.computeClientPenaltyCalc(
                dbo.computeClientSubOverdue(
                  podsub.U_DeliveryDateDTR, 
                  podsub.U_ClientReceivedDate, 
                  ISNULL(podsub.U_WaivedDays, 0), 
                  CAST(
                    ISNULL(clientsub.U_DCD, 0) as int
                  )
                )
              ), 
              dbo.computeInteluckPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                dbo.computeOverdueDays(
                  podsub.U_ActualHCRecDate, 
                  dbo.computePODSubmitDeadline(
                    podsub.U_DeliveryDateDTR, 
                    ISNULL(clientsub.U_CDC, 0)
                  ), 
                  ISNULL(podsub.U_HolidayOrWeekend, 0)
                )
              ), 
              dbo.computeLostPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                podsub.U_InitialHCRecDate, 
                podsub.U_DeliveryDateDTR, 
                pricingsub.U_TotalInitialTruckers
              ), 
              ISNULL(podsub.U_PenaltiesManual, 0)
            ), 
            ISNULL(podsub.U_PercPenaltyCharge, 0)
          )
        ) AS TotalAmount 
      FROM 
        [@PCTP_TP] tpsub 
        INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber 
        INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode 
        INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode 
        INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId 
        LEFT JOIN [@FirstratesTP] ratessub ON ratessub.U_BN = tpsub.U_BookingId 
        AND ratessub.U_PVNo = SUBSTRING(tpsub.U_PVNo, 1, 9) 
      WHERE 
        tpsub.U_BookingId = T0.U_BookingId
    ), 
    0
  ) --TOTAL AP 1 UNPAID  ------------
  WHEN CAST(
    (
      SELECT 
        DISTINCT SUBSTRING(
          (
            SELECT 
              CONCAT(', ', header.DocNum) AS [text() ] 
            FROM 
              PCH1 line 
              LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry 
            WHERE 
              header.CANCELED = 'N' 
              AND header.PaidSum = 0 
              AND (
                line.ItemCode = T0.U_BookingId 
                or REPLACE(
                  REPLACE(
                    RTRIM(
                      LTRIM(T0.U_PVNo)
                    ), 
                    ' ', 
                    ''
                  ), 
                  ',', 
                  ''
                ) LIKE '%' + RTRIM(
                  LTRIM(header.U_PVNo)
                ) + '%'
              ) FOR XML PATH (''), 
              TYPE
          ).value('text()[1]', 'nvarchar(max)'), 
          2, 
          1000
        ) DocEntry 
      FROM 
        OPCH header 
        LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry 
      WHERE 
        header.CANCELED = 'N' 
        AND (
          line.ItemCode = T0.U_BookingId 
          or REPLACE(
            REPLACE(
              RTRIM(
                LTRIM(T0.U_PVNo)
              ), 
              ' ', 
              ''
            ), 
            ',', 
            ''
          ) LIKE '%' + RTRIM(
            LTRIM(header.U_PVNo)
          ) + '%'
        )
    ) as nvarchar(max)
  ) IS NOT NULL 
  AND CAST(
    (
      SELECT 
        DISTINCT SUBSTRING(
          (
            SELECT 
              CONCAT(', ', header.DocNum) AS [text() ] 
            FROM 
              PCH1 line 
              LEFT JOIN OPCH header ON header.DocEntry = line.DocEntry 
            WHERE 
              header.CANCELED = 'N' 
              AND header.PaidSum > 0 
              AND (
                line.ItemCode = T0.U_BookingId 
                or REPLACE(
                  REPLACE(
                    RTRIM(
                      LTRIM(T0.U_PVNo)
                    ), 
                    ' ', 
                    ''
                  ), 
                  ',', 
                  ''
                ) LIKE '%' + RTRIM(
                  LTRIM(header.U_PVNo)
                ) + '%'
              ) FOR XML PATH (''), 
              TYPE
          ).value('text()[1]', 'nvarchar(max)'), 
          2, 
          1000
        ) DocEntry 
      FROM 
        OPCH header 
        LEFT JOIN PCH1 line ON line.DocEntry = header.DocEntry 
      WHERE 
        header.CANCELED = 'N' 
        AND (
          line.ItemCode = T0.U_BookingId 
          or REPLACE(
            REPLACE(
              RTRIM(
                LTRIM(T0.U_PVNo)
              ), 
              ' ', 
              ''
            ), 
            ',', 
            ''
          ) LIKE '%' + RTRIM(
            LTRIM(header.U_PVNo)
          ) + '%'
        )
    ) as nvarchar(max)
  ) IS NULL THEN ISNULL(
    (
      SELECT 
        DISTINCT (
          ISNULL(
            TRY_PARSE(ratessub.U_Amount AS FLOAT), 
            0
          )+ --ISNULL(tpsub.U_ActualRates,0) +
          ISNULL(tpsub.U_RateAdjustments, 0) + ISNULL(
            TRY_PARSE(ratessub.U_AddlAmount AS FLOAT), 
            0
          ) --+
          --ISNULL(tpsub.U_ActualDemurrage,0) +
          --ISNULL(tpsub.U_ActualCharges,0)+
          --ISNULL(NULLIF(tpsub.U_BoomTruck2,''),0) +
          --ISNULL(tpsub.U_OtherCharges,0) 
          ) - (
          ABS(
            dbo.computeTotalSubPenalties(
              dbo.computeClientPenaltyCalc(
                dbo.computeClientSubOverdue(
                  podsub.U_DeliveryDateDTR, 
                  podsub.U_ClientReceivedDate, 
                  ISNULL(podsub.U_WaivedDays, 0), 
                  CAST(
                    ISNULL(clientsub.U_DCD, 0) as int
                  )
                )
              ), 
              dbo.computeInteluckPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                dbo.computeOverdueDays(
                  podsub.U_ActualHCRecDate, 
                  dbo.computePODSubmitDeadline(
                    podsub.U_DeliveryDateDTR, 
                    ISNULL(clientsub.U_CDC, 0)
                  ), 
                  ISNULL(podsub.U_HolidayOrWeekend, 0)
                )
              ), 
              dbo.computeLostPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                podsub.U_InitialHCRecDate, 
                podsub.U_DeliveryDateDTR, 
                pricingsub.U_TotalInitialTruckers
              ), 
              ISNULL(podsub.U_PenaltiesManual, 0)
            )
          ) - dbo.computeTotalPenaltyWaived(
            dbo.computeTotalSubPenalties(
              dbo.computeClientPenaltyCalc(
                dbo.computeClientSubOverdue(
                  podsub.U_DeliveryDateDTR, 
                  podsub.U_ClientReceivedDate, 
                  ISNULL(podsub.U_WaivedDays, 0), 
                  CAST(
                    ISNULL(clientsub.U_DCD, 0) as int
                  )
                )
              ), 
              dbo.computeInteluckPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                dbo.computeOverdueDays(
                  podsub.U_ActualHCRecDate, 
                  dbo.computePODSubmitDeadline(
                    podsub.U_DeliveryDateDTR, 
                    ISNULL(clientsub.U_CDC, 0)
                  ), 
                  ISNULL(podsub.U_HolidayOrWeekend, 0)
                )
              ), 
              dbo.computeLostPenaltyCalc(
                dbo.computePODStatusPayment(
                  dbo.computeOverdueDays(
                    podsub.U_ActualHCRecDate, 
                    dbo.computePODSubmitDeadline(
                      podsub.U_DeliveryDateDTR, 
                      ISNULL(clientsub.U_CDC, 0)
                    ), 
                    ISNULL(podsub.U_HolidayOrWeekend, 0)
                  )
                ), 
                podsub.U_InitialHCRecDate, 
                podsub.U_DeliveryDateDTR, 
                pricingsub.U_TotalInitialTruckers
              ), 
              ISNULL(podsub.U_PenaltiesManual, 0)
            ), 
            ISNULL(podsub.U_PercPenaltyCharge, 0)
          )
        ) AS TotalAmount 
      FROM 
        [@PCTP_TP] tpsub 
        INNER JOIN [@PCTP_POD] podsub ON tpsub.U_BookingId = podsub.U_BookingNumber 
        INNER JOIN OCRD truckersub ON podsub.U_SAPTrucker = truckersub.CardCode 
        INNER JOIN OCRD clientsub ON U_SAPClient = clientsub.CardCode 
        INNER JOIN [dbo].[@PCTP_PRICING] pricingsub ON tpsub.U_BookingId = pricingsub.U_BookingId 
        LEFT JOIN [@FirstratesTP] ratessub ON ratessub.U_BN = tpsub.U_BookingId 
        AND ratessub.U_PVNo = SUBSTRING(tpsub.U_PVNo, 1, 9) 
      WHERE 
        tpsub.U_BookingId = T0.U_BookingId
    ), 
    0
  ) ELSE 0.00 END ELSE 0.00 END AS U_TotalAP 
FROM 
  [dbo].[@PCTP_TP] T0 WITH (NOLOCK) 
  INNER JOIN [dbo].[@PCTP_POD] pod ON T0.U_BookingId = pod.U_BookingNumber 
  AND CAST(
    pod.U_PODStatusDetail as nvarchar(max)
  ) LIKE '%Verified%' 
  LEFT JOIN OCRD T4 ON pod.U_SAPClient = T4.CardCode 
  LEFT JOIN [dbo].[@PCTP_PRICING] pricing ON T0.U_BookingId = pricing.U_BookingId 
  LEFT JOIN OCRD trucker ON pod.U_SAPTrucker = trucker.CardCode -- WHERE T0.U_BookingId IN (SELECT item FROM @BookingIdList)
