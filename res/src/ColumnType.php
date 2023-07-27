<?php

require_once __DIR__.'/../inc/restriction.php';

enum ColumnType: string {
    case DATE = 'DATE';
    case TEXT = 'TEXT';
    case INT = 'INT';
    case ALPHANUMERIC = 'ALPHANUMERIC';
    case FLOAT = 'FLOAT';
    case FORMULA = 'FORMULA';
    case TIME = 'TIME';
}
