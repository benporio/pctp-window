-------- PODSubmitDeadline ---------
DROP FUNCTION IF EXISTS dbo.computePODSubmitDeadline
GO
CREATE FUNCTION dbo.computePODSubmitDeadline
( 
	@DeliveryDateDTR date,
	@CDC int
)
RETURNS date
BEGIN
    IF ISDATE(CAST(@DeliveryDateDTR AS nvarchar)) = 0
	BEGIN
		RETURN NULL
	END
	RETURN DATEADD(day, @CDC, @DeliveryDateDTR)
END
GO
--SELECT dbo.computePODSubmitDeadline(CAST('2022-11-26 00:00:00.000' as datetime), 7) AS TEST_computePODSubmitDeadline

-------- OverdueDays ---------
DROP FUNCTION IF EXISTS dbo.computeOverdueDays;
GO
CREATE FUNCTION dbo.computeOverdueDays
( 
	@ActualHCRecDate date,
	@_PODSubmitDeadline date,
	@HolidayOrWeekend nvarchar(20)
)
RETURNS int
BEGIN
    IF ISNUMERIC(@HolidayOrWeekend) = 1
    BEGIN
        IF ISDATE(CAST(@ActualHCRecDate AS nvarchar)) = 0 
            AND ISDATE(CAST(@_PODSubmitDeadline AS nvarchar)) = 1
        BEGIN
            RETURN DATEDIFF(day, GETDATE(), @_PODSubmitDeadline) + CAST(ISNULL(@HolidayOrWeekend, 0) AS int)
        END
        IF ISDATE(CAST(@ActualHCRecDate AS nvarchar)) = 1 
            AND ISDATE(CAST(@_PODSubmitDeadline AS nvarchar)) = 1
        BEGIN
            RETURN DATEDIFF(day, @ActualHCRecDate, @_PODSubmitDeadline) + CAST(ISNULL(@HolidayOrWeekend, 0) AS int)
        END
    END
    IF ISNUMERIC(@HolidayOrWeekend) = 0
    BEGIN
        IF ISDATE(CAST(@ActualHCRecDate AS nvarchar)) = 0 
            AND ISDATE(CAST(@_PODSubmitDeadline AS nvarchar)) = 1
        BEGIN
            RETURN DATEDIFF(day, GETDATE(), @_PODSubmitDeadline) + 0
        END
        IF ISDATE(CAST(@ActualHCRecDate AS nvarchar)) = 1 
            AND ISDATE(CAST(@_PODSubmitDeadline AS nvarchar)) = 1
        BEGIN
            RETURN DATEDIFF(day, @ActualHCRecDate, @_PODSubmitDeadline) + 0
        END
    END
	RETURN 0
END
GO
--SELECT dbo.computeOverdueDays(NULL, dbo.computePODSubmitDeadline('2023-01-01', 7), 2) AS TEST_computePODSubmitDeadline

-------- PODStatusPayment ---------
DROP FUNCTION IF EXISTS dbo.computePODStatusPayment
GO
CREATE FUNCTION dbo.computePODStatusPayment
( 
	@_OverdueDays int
)
RETURNS nvarchar(6)
BEGIN
    IF @_OverdueDays >= 0
	BEGIN
		RETURN 'Ontime'
	END
	IF @_OverdueDays > -13 AND @_OverdueDays < 0
	BEGIN
		RETURN 'Late'
	END
	RETURN 'Lost'
END
GO
--SELECT dbo.computePODStatusPayment(1) AS TEST_computePODStatusPayment

-------- LostPenaltyCalc ---------
DROP FUNCTION IF EXISTS dbo.computeLostPenaltyCalc
GO
CREATE FUNCTION dbo.computeLostPenaltyCalc
( 
	@_PODStatusPayment nvarchar(6),
	@InitialHCRecDate date,
	@DeliveryDateDTR date,
	@TotalInitialTruckers float
)
RETURNS float
BEGIN
    IF ISDATE(CAST(@InitialHCRecDate AS nvarchar)) = 0 
		AND ISDATE(CAST(@DeliveryDateDTR AS nvarchar)) = 1
	BEGIN
		IF @_PODStatusPayment = 'Lost'
		BEGIN
			RETURN ISNULL(@TotalInitialTruckers, 0) * 2
		END
	END
	IF ISDATE(CAST(@InitialHCRecDate AS nvarchar)) = 1 
		AND ISDATE(CAST(@DeliveryDateDTR AS nvarchar)) = 1
	BEGIN
		IF @_PODStatusPayment = 'Lost'
		BEGIN
			RETURN -ABS(ISNULL(@TotalInitialTruckers, 0) * 2)
		END
	END
	RETURN 0
END
GO
--SELECT dbo.computeLostPenaltyCalc('Lost', NULL, '2023-01-12', 3.57) AS TEST_computeLostPenaltyCalc

-------- InteluckPenaltyCalc ---------
DROP FUNCTION IF EXISTS dbo.computeInteluckPenaltyCalc
GO
CREATE FUNCTION dbo.computeInteluckPenaltyCalc
( 
	@_PODStatusPayment nvarchar(6),
	@_OverdueDays int
)
RETURNS int
BEGIN
	RETURN CASE
		WHEN @_PODStatusPayment = 'Ontime' THEN 0
		WHEN @_PODStatusPayment = 'Late' THEN
			CASE
				WHEN ISNULL(@_OverdueDays, 0) < 0 THEN ISNULL(@_OverdueDays, 0) * 200
				ELSE 0
			END
		ELSE 0
	END
END
GO
--SELECT dbo.computeInteluckPenaltyCalc('Late', -1) AS TEST_computeInteluckPenaltyCalc

-------- ClientSubOverdue ---------
DROP FUNCTION IF EXISTS dbo.computeClientSubOverdue
GO
CREATE FUNCTION dbo.computeClientSubOverdue
( 
	@DeliveryDateDTR date,
	@ClientReceivedDate date,
	@WaivedDays nvarchar(20),
	@DCD int
)
RETURNS int
BEGIN
    IF ISNUMERIC(@WaivedDays) = 1
    BEGIN
	    RETURN DATEDIFF(day, @ClientReceivedDate, @DeliveryDateDTR) + ISNULL(@DCD, 0) + CAST(ISNULL(@WaivedDays, 0) AS int)
    END
    IF ISNUMERIC(@WaivedDays) = 0
    BEGIN
	    RETURN DATEDIFF(day, @ClientReceivedDate, @DeliveryDateDTR) + ISNULL(@DCD, 0) + 0
    END
    RETURN 0
END
GO
--SELECT dbo.computeClientSubOverdue('2022-11-22 00:00:00.000', '2022-11-19 00:00:00.000', 0, 2) AS TEST_computeClientSubOverdue

-------- ClientPenaltyCalc ---------
DROP FUNCTION IF EXISTS dbo.computeClientPenaltyCalc
GO
CREATE FUNCTION dbo.computeClientPenaltyCalc
( 
	@_ClientSubOverdue int
)
RETURNS float
BEGIN
	RETURN CASE
		WHEN ISNULL(@_ClientSubOverdue, 0) < 0 THEN ISNULL(@_ClientSubOverdue, 0) * 200
		ELSE 0
	END
END
GO
--SELECT dbo.computeClientPenaltyCalc(-2) AS TEST_computeClientPenaltyCalc

-------- TotalSubPenalties ---------
DROP FUNCTION IF EXISTS dbo.computeTotalSubPenalties
GO
CREATE FUNCTION dbo.computeTotalSubPenalties
( 
	@_ClientPenaltyCalc float,
	@_InteluckPenaltyCalc float,
	@_LostPenaltyCalc float,
	@PenaltiesManual float
)
RETURNS float
BEGIN
	RETURN ISNULL(@_ClientPenaltyCalc, 0) + ISNULL(@_InteluckPenaltyCalc, 0) + ISNULL(@_LostPenaltyCalc, 0) + ISNULL(@PenaltiesManual, 0)
END
GO
--SELECT dbo.computeTotalSubPenalties(500, 1000, 100, 30) AS TEST_computeTotalSubPenalties

-------- TotalPenaltyWaived ---------
DROP FUNCTION IF EXISTS dbo.computeTotalPenaltyWaived
GO
CREATE FUNCTION dbo.computeTotalPenaltyWaived
( 
	@_TotalSubPenalties float,
	@PercPenaltyCharge float
)
RETURNS float
BEGIN
	RETURN ABS(ISNULL(@_TotalSubPenalties, 0)  - (ISNULL(@PercPenaltyCharge, 0) * ISNULL(@_TotalSubPenalties, 0)))
END
--GO
--SELECT dbo.computeTotalPenaltyWaived(500, 0.10) AS TEST_computeTotalPenaltyWaived