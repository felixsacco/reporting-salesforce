/**
 * @description Results display component for query results.
 *              Consumes parent-managed reactive state and renders paged rows.
 *
 * @author Mritesh
 * @date 2026-04-18
 * @version 2.0.0
 */
import { LightningElement, api } from "lwc";

const DEFAULT_PAGE_SIZE = 50;
const URL_KEY_PREFIX = "__url_";

const DATE_FIELDS = new Set([
  "CreatedDate",
  "LastModifiedDate",
  "SystemModstamp"
]);
const NUMBER_FIELDS = new Set([
  "BodyLength",
  "ContentSize",
  "NumberOfEmployees"
]);
const URL_FALLBACK_FIELDS = new Set(["Id", "Name", "Title"]);

const DATE_TYPES = new Set(["date", "datetime"]);
const NUMBER_TYPES = new Set([
  "int",
  "integer",
  "long",
  "double",
  "currency",
  "percent",
  "number"
]);
const BOOLEAN_TYPES = new Set(["boolean"]);
const URL_TYPES = new Set(["id", "reference", "url"]);

export default class ResultsDisplay extends LightningElement {
  @api isLoading = false;
  @api errorState = null;

  _resultsState = null;

  columns = [];
  allRows = [];
  currentPage = 1;
  pageSize = DEFAULT_PAGE_SIZE;
  recordCount = 0;

  selectedFields = [];
  fieldLabels = {};
  fieldTypeMap = {};
  urlFieldKeys = {};

  @api
  get resultsState() {
    return this._resultsState;
  }

  set resultsState(value) {
    this._resultsState = value && typeof value === "object" ? value : null;
    this.applyResultsState();
  }

  applyResultsState() {
    if (!this._resultsState) {
      this.columns = [];
      this.allRows = [];
      this.recordCount = 0;
      this.currentPage = 1;
      this.selectedFields = [];
      this.fieldLabels = {};
      this.fieldTypeMap = {};
      this.urlFieldKeys = {};
      return;
    }

    const records = Array.isArray(this._resultsState.records)
      ? this._resultsState.records
      : [];

    this.selectedFields = Array.isArray(this._resultsState.fields)
      ? this._resultsState.fields
      : [];
    this.fieldLabels =
      this._resultsState.fieldLabels &&
      typeof this._resultsState.fieldLabels === "object"
        ? this._resultsState.fieldLabels
        : {};
    this.fieldTypeMap =
      this._resultsState.fieldTypeMap &&
      typeof this._resultsState.fieldTypeMap === "object"
        ? this._resultsState.fieldTypeMap
        : {};
    this.recordCount =
      typeof this._resultsState.recordCount === "number"
        ? this._resultsState.recordCount
        : records.length;

    this.urlFieldKeys = this.buildUrlFieldKeys(records);
    this.columns = this.buildColumns();
    this.allRows = this.buildRows(records);
    this.currentPage = 1;
  }

  buildColumns() {
    return this.selectedFields.map((fieldName) => {
      if (this.isUrlField(fieldName)) {
        return {
          label: this.fieldLabels[fieldName] || fieldName,
          fieldName: this.urlFieldKeys[fieldName],
          type: "url",
          typeAttributes: {
            label: { fieldName },
            target: "_blank"
          }
        };
      }

      return {
        label: this.fieldLabels[fieldName] || fieldName,
        fieldName,
        type: this.resolveColumnType(fieldName)
      };
    });
  }

  buildRows(records) {
    return records.map((record, index) => {
      const normalizedRecord =
        record && typeof record === "object" ? { ...record } : {};
      const rowIdentifier = normalizedRecord.Id || `row-${index + 1}`;
      const row = {
        __rowKey: `${rowIdentifier}-${index}`,
        ...normalizedRecord
      };

      Object.entries(this.urlFieldKeys).forEach(([fieldName, urlFieldName]) => {
        const displayValue = row[fieldName];
        const targetId = row.Id || (fieldName === "Id" ? displayValue : null);
        if (displayValue && targetId) {
          row[urlFieldName] = `/${targetId}`;
        }
      });

      return row;
    });
  }

  buildUrlFieldKeys(records) {
    const existingKeys = new Set();
    records.forEach((record) => {
      if (record && typeof record === "object") {
        Object.keys(record).forEach((recordKey) => existingKeys.add(recordKey));
      }
    });

    const urlKeys = {};
    const reserved = new Set();

    this.selectedFields.forEach((fieldName) => {
      if (!this.isUrlField(fieldName)) {
        return;
      }

      const sanitizedField = String(fieldName).replace(/[^A-Za-z0-9_]/g, "_");
      const base = `${URL_KEY_PREFIX}${sanitizedField}`;
      let candidate = base;
      let suffix = 1;

      while (existingKeys.has(candidate) || reserved.has(candidate)) {
        candidate = `${base}_${suffix}`;
        suffix += 1;
      }

      reserved.add(candidate);
      urlKeys[fieldName] = candidate;
    });

    return urlKeys;
  }

  resolveColumnType(fieldName) {
    const typeFromMap = this.normalizeType(this.fieldTypeMap[fieldName]);

    if (DATE_TYPES.has(typeFromMap)) {
      return "date";
    }
    if (NUMBER_TYPES.has(typeFromMap)) {
      return "number";
    }
    if (BOOLEAN_TYPES.has(typeFromMap)) {
      return "boolean";
    }

    // Fall back to a small heuristic map when type metadata is not available.
    if (DATE_FIELDS.has(fieldName)) {
      return "date";
    }
    if (NUMBER_FIELDS.has(fieldName)) {
      return "number";
    }

    return "text";
  }

  isUrlField(fieldName) {
    const typeFromMap = this.normalizeType(this.fieldTypeMap[fieldName]);
    if (URL_TYPES.has(typeFromMap)) {
      return true;
    }

    return URL_FALLBACK_FIELDS.has(fieldName);
  }

  normalizeType(rawType) {
    return typeof rawType === "string" ? rawType.toLowerCase() : "";
  }

  handlePreviousPage() {
    if (this.currentPage > 1) {
      this.currentPage -= 1;
    }
  }

  handleNextPage() {
    if (this.currentPage < this.totalPages) {
      this.currentPage += 1;
    }
  }

  handlePageSelect(event) {
    const page = Number.parseInt(event.currentTarget?.dataset?.page, 10);
    if (!Number.isNaN(page)) {
      this.currentPage = Math.min(Math.max(page, 1), this.totalPages);
    }
  }

  get hasResults() {
    return this.allRows.length > 0;
  }

  get hasError() {
    return Boolean(
      this.errorState?.userSafeMessage || this.errorState?.errorMessage
    );
  }

  get errorMessage() {
    return (
      this.errorState?.userSafeMessage ||
      this.errorState?.errorMessage ||
      "An unexpected query error occurred."
    );
  }

  get noResults() {
    return !this.isLoading && !this.hasResults;
  }

  get totalPages() {
    return Math.max(1, Math.ceil(this.allRows.length / this.pageSize));
  }

  get visibleRows() {
    const startIndex = (this.currentPage - 1) * this.pageSize;
    return this.allRows.slice(startIndex, startIndex + this.pageSize);
  }

  get showPagination() {
    return this.hasResults && this.totalPages > 1;
  }

  get pageItems() {
    return Array.from({ length: this.totalPages }, (_, index) => {
      const page = index + 1;
      return {
        key: `page-${page}`,
        page,
        label: String(page),
        variant: page === this.currentPage ? "brand" : "neutral"
      };
    });
  }

  get disablePrevious() {
    return this.currentPage <= 1;
  }

  get disableNext() {
    return this.currentPage >= this.totalPages;
  }

  get pageStatus() {
    return `Page ${this.currentPage} of ${this.totalPages}`;
  }
}
