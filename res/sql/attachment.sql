SELECT
	CONCAT('pod', pod.U_BookingNumber) AS PodTabCode,
	CONCAT('billing', billing.Code) AS BillingTabCode,
	CONCAT('tp', tp.Code) AS TpTabCode,
	pod.U_Attachment AS Attachment
FROM [@PCTP_POD] pod WITH (NOLOCK)
LEFT JOIN [@PCTP_BILLING] billing ON billing.U_BookingId = pod.U_BookingNumber
LEFT JOIN [@PCTP_TP] tp ON tp.U_BookingId = pod.U_BookingNumber
