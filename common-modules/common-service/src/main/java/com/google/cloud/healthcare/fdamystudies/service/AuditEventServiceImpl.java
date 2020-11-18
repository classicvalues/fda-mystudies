/*
 * Copyright 2020 Google LLC
 *
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT.
 */

package com.google.cloud.healthcare.fdamystudies.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.google.cloud.healthcare.fdamystudies.beans.AuditLogEventRequest;
import com.google.cloud.healthcare.fdamystudies.common.JsonUtils;
import org.slf4j.ext.XLogger;
import org.slf4j.ext.XLoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

@Service
@ConditionalOnProperty(
    value = "commonservice.auditlogevent.enabled",
    havingValue = "true",
    matchIfMissing = true)
public class AuditEventServiceImpl implements AuditEventService {

  private XLogger logger = XLoggerFactory.getXLogger(AuditEventServiceImpl.class.getName());

  private static final String AUDIT_LOG_NAME = "application-audit-log";

  @Override
  public void postAuditLogEvent(AuditLogEventRequest auditRequest) {
    logger.entry(
        String.format("begin postAuditLogEvent() for %s event", auditRequest.getEventCode()));
    try {
      String auditRequestJson = JsonUtils.asJsonString(auditRequest);
      logger.info(
          String.format("%s event details %s", auditRequest.getEventCode(), auditRequestJson));
    } catch (JsonProcessingException e) {
      // TODO Auto-generated catch block
      e.printStackTrace();
    }
    //   Logging logging = LoggingOptions.getDefaultInstance().getService();

    //    // The data to write to the log
    //    Map<String, Object> jsonPayloadMap = getObjectMapper().convertValue(auditRequest,
    // Map.class);
    //
    //    LogEntry entry =
    //        LogEntry.newBuilder(Payload.JsonPayload.of(jsonPayloadMap))
    //            .setTimestamp(auditRequest.getOccurred().getTime())
    //            .setSeverity(Severity.INFO)
    //            .setLogName(AUDIT_LOG_NAME)
    //            .setResource(MonitoredResource.newBuilder("global").build())
    //            .build();
    //
    //    // Writes the log entry asynchronously
    //    logging.write(Collections.singleton(entry));
    //    logger.exit(
    //        String.format("postAuditLogEvent() for %s event finished",
    // auditRequest.getEventCode()));
  }
}
