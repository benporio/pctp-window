<?php

require_once __DIR__.'/../inc/restriction.php';

enum ColumnViewType: string {
    case EDIT = 'EDIT';
    case AUTO = 'AUTO';
    case DROPDOWN = 'DROPDOWN';
    case HIDDEN = 'HIDDEN';
}
