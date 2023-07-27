<?php

require_once __DIR__.'/../inc/restriction.php';

class TreasuryTab extends APctpWindowTab
{

    public function __construct(PctpWindowSettings $settings)
    {
        $this->script = file_get_contents(__DIR__.'/../sql/treasury.sql');
        $this->columnDefinitions = [
            new ColumnDefinition('BookingId', 'Booking ID', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('BookingDate', 'Booking Date', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('TruckerName', 'Trucker\'s Name', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('PaymentVoucher', 'Payment Voucher #', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('ORRefNo', 'OR Reference #', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('ActualPaymentDate', 'Actual Payment Date', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('PaymentReference', 'Payment Reference', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('PaymentStatus', 'Payment Status', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('PODNum', 'POD Document Number', ColumnType::ALPHANUMERIC),
        ];

        parent::__construct(
            'Code',
            $settings->tabTables[lcfirst(get_class($this))],
            $settings
        );
    }

    protected function postFetchProcessRows(array $rows): array {
        return $rows;
    }

    protected function postProcessPostingTransaction(object $args): mixed {
        return $args;
    }

    protected function preUpdateProcessRows(PctpWindowModel &$model, array $rows): array {
        return $rows;
    }

    protected function postUpdateProcessRows(PctpWindowModel &$model, array $rows) {
        // code here
    }
}