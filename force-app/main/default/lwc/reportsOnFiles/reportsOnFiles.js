/**
 * @description Container component for the Reporting on Files application.
 *              Owns lifecycle state and declaratively passes it to resultsDisplay.
 *
 * @author Agent Mritesh
 * @date 2026-04-18
 * @version 2.0.0
 */
import { LightningElement } from "lwc";

export default class ReportsOnFiles extends LightningElement {
  isLoading = false;
  errorState = null;
  resultsState = null;
  latestRequestId = null;

  /**
   * @description Handles query lifecycle start event.
   * @param {CustomEvent} event Event envelope containing request metadata.
   * @returns {void}
   */
  handleQueryStart(event) {
    const requestId = event?.detail?.requestId;
    if (!requestId) {
      return;
    }

    this.latestRequestId = requestId;
    this.isLoading = true;
    this.errorState = null;
  }

  /**
   * @description Handles successful query responses with stale request protection.
   * @param {CustomEvent} event Event envelope with query results.
   * @returns {void}
   */
  handleQuerySuccess(event) {
    const detail = event?.detail ?? {};
    if (!this.isLatestRequest(detail.requestId)) {
      return;
    }

    const records = Array.isArray(detail.records) ? detail.records : [];
    this.resultsState = {
      objectType: detail.objectType,
      fields: Array.isArray(detail.fields) ? detail.fields : [],
      fieldLabels:
        detail.fieldLabels && typeof detail.fieldLabels === "object"
          ? detail.fieldLabels
          : {},
      records,
      recordCount:
        typeof detail.recordCount === "number"
          ? detail.recordCount
          : records.length,
      fieldTypeMap:
        detail.fieldTypeMap && typeof detail.fieldTypeMap === "object"
          ? detail.fieldTypeMap
          : undefined
    };

    this.errorState = null;
    this.isLoading = false;
  }

  /**
   * @description Handles failed query responses with stale request protection.
   * @param {CustomEvent} event Event envelope with error details.
   * @returns {void}
   */
  handleQueryError(event) {
    const detail = event?.detail ?? {};
    if (!this.isLatestRequest(detail.requestId)) {
      return;
    }

    this.errorState = {
      errorCode: detail.errorCode || "UNKNOWN_ERROR",
      errorMessage: detail.errorMessage || "An unexpected error occurred.",
      userSafeMessage:
        detail.userSafeMessage ||
        "The query failed. Please review inputs and try again."
    };
    this.isLoading = false;
  }

  /**
   * @description Legacy bridge to keep compatibility while queryBuilder migrates.
   * @param {CustomEvent} event Legacy queryresults payload.
   * @returns {void}
   */
  handleLegacyQueryResults(event) {
    const detail = event?.detail ?? {};
    const records = Array.isArray(detail.results) ? detail.results : [];

    this.resultsState = {
      objectType: detail.objectType,
      fields: Array.isArray(detail.fields) ? detail.fields : [],
      fieldLabels:
        detail.fieldLabels && typeof detail.fieldLabels === "object"
          ? detail.fieldLabels
          : {},
      records,
      recordCount: records.length,
      fieldTypeMap: undefined
    };
    this.errorState = null;
    this.isLoading = false;
  }

  isLatestRequest(requestId) {
    return Boolean(requestId) && requestId === this.latestRequestId;
  }
}
