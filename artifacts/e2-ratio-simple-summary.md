# E2 Ratio Simple Analysis Results

**Generated**: 2025-09-27 07:28:37
**Actor**: Cursor-Local (Observability Copilot)
**Test Duration**: 15 seconds

## Current Configuration
- **Batch Timeout**: 500ms
- **Batch Size**: 256

## Test Results
- **Logs Generated**: 128
- **Logs Processed**: 0
- **Success Rate**: 0%
- **Queue Size**: # HELP otelcol_exporter_queue_capacity Fixed capacity of the retry queue (in batches)
# TYPE otelcol_exporter_queue_capacity gauge
otelcol_exporter_queue_capacity{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 5000
# HELP otelcol_exporter_queue_size Current size of the retry queue (in batches)
# TYPE otelcol_exporter_queue_size gauge
otelcol_exporter_queue_size{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_exporter_send_failed_log_records Number of log records in failed attempts to send to destination.
# TYPE otelcol_exporter_send_failed_log_records counter
otelcol_exporter_send_failed_log_records{exporter="logging",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
otelcol_exporter_send_failed_log_records{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_exporter_send_failed_metric_points Number of metric points in failed attempts to send to destination.
# TYPE otelcol_exporter_send_failed_metric_points counter
otelcol_exporter_send_failed_metric_points{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_exporter_send_failed_spans Number of spans in failed attempts to send to destination.
# TYPE otelcol_exporter_send_failed_spans counter
otelcol_exporter_send_failed_spans{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_exporter_sent_log_records Number of log record successfully sent to destination.
# TYPE otelcol_exporter_sent_log_records counter
otelcol_exporter_sent_log_records{exporter="logging",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 5107
otelcol_exporter_sent_log_records{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 5107
# HELP otelcol_exporter_sent_metric_points Number of metric points successfully sent to destination.
# TYPE otelcol_exporter_sent_metric_points counter
otelcol_exporter_sent_metric_points{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_exporter_sent_spans Number of spans successfully sent to destination.
# TYPE otelcol_exporter_sent_spans counter
otelcol_exporter_sent_spans{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_fileconsumer_open_files Number of open files
# TYPE otelcol_fileconsumer_open_files gauge
otelcol_fileconsumer_open_files{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_fileconsumer_reading_files Number of open files that are being read
# TYPE otelcol_fileconsumer_reading_files gauge
otelcol_fileconsumer_reading_files{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_process_cpu_seconds Total CPU user and system time in seconds
# TYPE otelcol_process_cpu_seconds counter
otelcol_process_cpu_seconds{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 693.421875
# HELP otelcol_process_memory_rss Total physical memory (resident set size)
# TYPE otelcol_process_memory_rss gauge
otelcol_process_memory_rss{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 1.33996544e+08
# HELP otelcol_process_runtime_heap_alloc_bytes Bytes of allocated heap objects (see 'go doc runtime.MemStats.HeapAlloc')
# TYPE otelcol_process_runtime_heap_alloc_bytes gauge
otelcol_process_runtime_heap_alloc_bytes{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 7.144776e+07
# HELP otelcol_process_runtime_total_alloc_bytes Cumulative bytes allocated for heap objects (see 'go doc runtime.MemStats.TotalAlloc')
# TYPE otelcol_process_runtime_total_alloc_bytes counter
otelcol_process_runtime_total_alloc_bytes{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 9.8353111632e+10
# HELP otelcol_process_runtime_total_sys_memory_bytes Total bytes of memory obtained from the OS (see 'go doc runtime.MemStats.Sys')
# TYPE otelcol_process_runtime_total_sys_memory_bytes gauge
otelcol_process_runtime_total_sys_memory_bytes{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 1.2453708e+08
# HELP otelcol_process_uptime Uptime of the process
# TYPE otelcol_process_uptime counter
otelcol_process_uptime{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 15745.5537554
# HELP otelcol_processor_accepted_log_records Number of log records successfully pushed into the next component in the pipeline.
# TYPE otelcol_processor_accepted_log_records counter
otelcol_processor_accepted_log_records{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 5108
# HELP otelcol_processor_accepted_metric_points Number of metric points successfully pushed into the next component in the pipeline.
# TYPE otelcol_processor_accepted_metric_points counter
otelcol_processor_accepted_metric_points{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_accepted_spans Number of spans successfully pushed into the next component in the pipeline.
# TYPE otelcol_processor_accepted_spans counter
otelcol_processor_accepted_spans{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_batch_batch_send_size Number of units in the batch
# TYPE otelcol_processor_batch_batch_send_size histogram
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 4215
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="250"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="6000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="7000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="8000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="9000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4216
otelcol_processor_batch_batch_send_size_sum{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 5111
otelcol_processor_batch_batch_send_size_count{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="250"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="6000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="7000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="8000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="9000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4
otelcol_processor_batch_batch_send_size_sum{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_batch_batch_send_size_count{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_batch_metadata_cardinality Number of distinct metadata value combinations being processed
# TYPE otelcol_processor_batch_metadata_cardinality gauge
otelcol_processor_batch_metadata_cardinality{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 1
# HELP otelcol_processor_batch_timeout_trigger_send Number of times the batch was sent due to a timeout trigger
# TYPE otelcol_processor_batch_timeout_trigger_send counter
otelcol_processor_batch_timeout_trigger_send{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4216
otelcol_processor_batch_timeout_trigger_send{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_dropped_log_records Number of log records that were dropped.
# TYPE otelcol_processor_dropped_log_records counter
otelcol_processor_dropped_log_records{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_dropped_metric_points Number of metric points that were dropped.
# TYPE otelcol_processor_dropped_metric_points counter
otelcol_processor_dropped_metric_points{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_dropped_spans Number of spans that were dropped.
# TYPE otelcol_processor_dropped_spans counter
otelcol_processor_dropped_spans{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_filter_logs_filtered Number of logs dropped by the filter processor
# TYPE otelcol_processor_filter_logs_filtered counter
otelcol_processor_filter_logs_filtered{filter="filter/drop_noise",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 1
# HELP otelcol_processor_inserted_log_records Number of log records that were inserted.
# TYPE otelcol_processor_inserted_log_records counter
otelcol_processor_inserted_log_records{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_inserted_metric_points Number of metric points that were inserted.
# TYPE otelcol_processor_inserted_metric_points counter
otelcol_processor_inserted_metric_points{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_inserted_spans Number of spans that were inserted.
# TYPE otelcol_processor_inserted_spans counter
otelcol_processor_inserted_spans{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_refused_log_records Number of log records that were rejected by the next component in the pipeline.
# TYPE otelcol_processor_refused_log_records counter
otelcol_processor_refused_log_records{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_refused_metric_points Number of metric points that were rejected by the next component in the pipeline.
# TYPE otelcol_processor_refused_metric_points counter
otelcol_processor_refused_metric_points{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_refused_spans Number of spans that were rejected by the next component in the pipeline.
# TYPE otelcol_processor_refused_spans counter
otelcol_processor_refused_spans{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_tail_sampling_count_traces_sampled Count of traces that were sampled or not per sampling policy
# TYPE otelcol_processor_tail_sampling_count_traces_sampled counter
otelcol_processor_tail_sampling_count_traces_sampled{policy="baseline",sampled="false",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_tail_sampling_count_traces_sampled{policy="canary",sampled="true",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_tail_sampling_count_traces_sampled{policy="errors",sampled="false",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_tail_sampling_count_traces_sampled{policy="slow-traces",sampled="false",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_tail_sampling_global_count_traces_sampled Global count of traces that were sampled or not by at least one policy
# TYPE otelcol_processor_tail_sampling_global_count_traces_sampled counter
otelcol_processor_tail_sampling_global_count_traces_sampled{sampled="true",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_tail_sampling_new_trace_id_received Counts the arrival of new traces
# TYPE otelcol_processor_tail_sampling_new_trace_id_received counter
otelcol_processor_tail_sampling_new_trace_id_received{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_tail_sampling_sampling_decision_latency Latency (in microseconds) of a given sampling policy
# TYPE otelcol_processor_tail_sampling_sampling_decision_latency histogram
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="150"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="200"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="300"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="400"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_sum{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
otelcol_processor_tail_sampling_sampling_decision_latency_count{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="150"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="200"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="300"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="400"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_sum{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
otelcol_processor_tail_sampling_sampling_decision_latency_count{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="150"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="200"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="300"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="400"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_sum{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
otelcol_processor_tail_sampling_sampling_decision_latency_count{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="150"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="200"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="300"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="400"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_sum{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
otelcol_processor_tail_sampling_sampling_decision_latency_count{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_tail_sampling_sampling_decision_timer_latency Latency (in microseconds) of each run of the sampling decision timer
# TYPE otelcol_processor_tail_sampling_sampling_decision_timer_latency histogram
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="150"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="200"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="300"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="400"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_sum{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 1008
otelcol_processor_tail_sampling_sampling_decision_timer_latency_count{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_tail_sampling_sampling_policy_evaluation_error Count of sampling policy evaluation errors
# TYPE otelcol_processor_tail_sampling_sampling_policy_evaluation_error counter
otelcol_processor_tail_sampling_sampling_policy_evaluation_error{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_tail_sampling_sampling_trace_dropped_too_early Count of traces that needed to be dropped before the configured wait time
# TYPE otelcol_processor_tail_sampling_sampling_trace_dropped_too_early counter
otelcol_processor_tail_sampling_sampling_trace_dropped_too_early{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_tail_sampling_sampling_traces_on_memory Tracks the number of traces current on memory
# TYPE otelcol_processor_tail_sampling_sampling_traces_on_memory gauge
otelcol_processor_tail_sampling_sampling_traces_on_memory{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 2
# HELP otelcol_receiver_accepted_log_records Number of log records successfully pushed into the pipeline.
# TYPE otelcol_receiver_accepted_log_records counter
otelcol_receiver_accepted_log_records{receiver="filelog",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport=""} 182
otelcol_receiver_accepted_log_records{receiver="otlp",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport="http"} 48
otelcol_receiver_accepted_log_records{receiver="windowseventlog/application",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport=""} 4852
otelcol_receiver_accepted_log_records{receiver="windowseventlog/system",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport=""} 26
# HELP otelcol_receiver_accepted_metric_points Number of metric points successfully pushed into the pipeline.
# TYPE otelcol_receiver_accepted_metric_points counter
otelcol_receiver_accepted_metric_points{receiver="otlp",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport="http"} 2
# HELP otelcol_receiver_accepted_spans Number of spans successfully pushed into the pipeline.
# TYPE otelcol_receiver_accepted_spans counter
otelcol_receiver_accepted_spans{receiver="otlp",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport="http"} 2
# HELP otelcol_receiver_refused_log_records Number of log records that could not be pushed into the pipeline.
# TYPE otelcol_receiver_refused_log_records counter
otelcol_receiver_refused_log_records{receiver="filelog",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport=""} 0
otelcol_receiver_refused_log_records{receiver="otlp",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport="http"} 0
otelcol_receiver_refused_log_records{receiver="windowseventlog/application",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport=""} 0
otelcol_receiver_refused_log_records{receiver="windowseventlog/system",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport=""} 0
# HELP otelcol_receiver_refused_metric_points Number of metric points that could not be pushed into the pipeline.
# TYPE otelcol_receiver_refused_metric_points counter
otelcol_receiver_refused_metric_points{receiver="otlp",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport="http"} 0
# HELP otelcol_receiver_refused_spans Number of spans that could not be pushed into the pipeline.
# TYPE otelcol_receiver_refused_spans counter
otelcol_receiver_refused_spans{receiver="otlp",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport="http"} 0
# HELP target_info Target metadata
# TYPE target_info gauge
target_info{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 1

- **Queue Capacity**: # HELP otelcol_exporter_queue_capacity Fixed capacity of the retry queue (in batches)
# TYPE otelcol_exporter_queue_capacity gauge
otelcol_exporter_queue_capacity{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 5000
# HELP otelcol_exporter_queue_size Current size of the retry queue (in batches)
# TYPE otelcol_exporter_queue_size gauge
otelcol_exporter_queue_size{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_exporter_send_failed_log_records Number of log records in failed attempts to send to destination.
# TYPE otelcol_exporter_send_failed_log_records counter
otelcol_exporter_send_failed_log_records{exporter="logging",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
otelcol_exporter_send_failed_log_records{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_exporter_send_failed_metric_points Number of metric points in failed attempts to send to destination.
# TYPE otelcol_exporter_send_failed_metric_points counter
otelcol_exporter_send_failed_metric_points{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_exporter_send_failed_spans Number of spans in failed attempts to send to destination.
# TYPE otelcol_exporter_send_failed_spans counter
otelcol_exporter_send_failed_spans{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_exporter_sent_log_records Number of log record successfully sent to destination.
# TYPE otelcol_exporter_sent_log_records counter
otelcol_exporter_sent_log_records{exporter="logging",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 5107
otelcol_exporter_sent_log_records{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 5107
# HELP otelcol_exporter_sent_metric_points Number of metric points successfully sent to destination.
# TYPE otelcol_exporter_sent_metric_points counter
otelcol_exporter_sent_metric_points{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_exporter_sent_spans Number of spans successfully sent to destination.
# TYPE otelcol_exporter_sent_spans counter
otelcol_exporter_sent_spans{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_fileconsumer_open_files Number of open files
# TYPE otelcol_fileconsumer_open_files gauge
otelcol_fileconsumer_open_files{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_fileconsumer_reading_files Number of open files that are being read
# TYPE otelcol_fileconsumer_reading_files gauge
otelcol_fileconsumer_reading_files{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_process_cpu_seconds Total CPU user and system time in seconds
# TYPE otelcol_process_cpu_seconds counter
otelcol_process_cpu_seconds{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 693.421875
# HELP otelcol_process_memory_rss Total physical memory (resident set size)
# TYPE otelcol_process_memory_rss gauge
otelcol_process_memory_rss{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 1.33996544e+08
# HELP otelcol_process_runtime_heap_alloc_bytes Bytes of allocated heap objects (see 'go doc runtime.MemStats.HeapAlloc')
# TYPE otelcol_process_runtime_heap_alloc_bytes gauge
otelcol_process_runtime_heap_alloc_bytes{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 7.144776e+07
# HELP otelcol_process_runtime_total_alloc_bytes Cumulative bytes allocated for heap objects (see 'go doc runtime.MemStats.TotalAlloc')
# TYPE otelcol_process_runtime_total_alloc_bytes counter
otelcol_process_runtime_total_alloc_bytes{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 9.8353111632e+10
# HELP otelcol_process_runtime_total_sys_memory_bytes Total bytes of memory obtained from the OS (see 'go doc runtime.MemStats.Sys')
# TYPE otelcol_process_runtime_total_sys_memory_bytes gauge
otelcol_process_runtime_total_sys_memory_bytes{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 1.2453708e+08
# HELP otelcol_process_uptime Uptime of the process
# TYPE otelcol_process_uptime counter
otelcol_process_uptime{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 15745.5537554
# HELP otelcol_processor_accepted_log_records Number of log records successfully pushed into the next component in the pipeline.
# TYPE otelcol_processor_accepted_log_records counter
otelcol_processor_accepted_log_records{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 5108
# HELP otelcol_processor_accepted_metric_points Number of metric points successfully pushed into the next component in the pipeline.
# TYPE otelcol_processor_accepted_metric_points counter
otelcol_processor_accepted_metric_points{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_accepted_spans Number of spans successfully pushed into the next component in the pipeline.
# TYPE otelcol_processor_accepted_spans counter
otelcol_processor_accepted_spans{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_batch_batch_send_size Number of units in the batch
# TYPE otelcol_processor_batch_batch_send_size histogram
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 4215
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="250"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="6000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="7000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="8000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="9000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4216
otelcol_processor_batch_batch_send_size_sum{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 5111
otelcol_processor_batch_batch_send_size_count{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="250"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="6000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="7000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="8000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="9000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4
otelcol_processor_batch_batch_send_size_sum{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_batch_batch_send_size_count{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_batch_metadata_cardinality Number of distinct metadata value combinations being processed
# TYPE otelcol_processor_batch_metadata_cardinality gauge
otelcol_processor_batch_metadata_cardinality{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 1
# HELP otelcol_processor_batch_timeout_trigger_send Number of times the batch was sent due to a timeout trigger
# TYPE otelcol_processor_batch_timeout_trigger_send counter
otelcol_processor_batch_timeout_trigger_send{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4216
otelcol_processor_batch_timeout_trigger_send{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_dropped_log_records Number of log records that were dropped.
# TYPE otelcol_processor_dropped_log_records counter
otelcol_processor_dropped_log_records{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_dropped_metric_points Number of metric points that were dropped.
# TYPE otelcol_processor_dropped_metric_points counter
otelcol_processor_dropped_metric_points{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_dropped_spans Number of spans that were dropped.
# TYPE otelcol_processor_dropped_spans counter
otelcol_processor_dropped_spans{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_filter_logs_filtered Number of logs dropped by the filter processor
# TYPE otelcol_processor_filter_logs_filtered counter
otelcol_processor_filter_logs_filtered{filter="filter/drop_noise",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 1
# HELP otelcol_processor_inserted_log_records Number of log records that were inserted.
# TYPE otelcol_processor_inserted_log_records counter
otelcol_processor_inserted_log_records{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_inserted_metric_points Number of metric points that were inserted.
# TYPE otelcol_processor_inserted_metric_points counter
otelcol_processor_inserted_metric_points{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_inserted_spans Number of spans that were inserted.
# TYPE otelcol_processor_inserted_spans counter
otelcol_processor_inserted_spans{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_refused_log_records Number of log records that were rejected by the next component in the pipeline.
# TYPE otelcol_processor_refused_log_records counter
otelcol_processor_refused_log_records{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_refused_metric_points Number of metric points that were rejected by the next component in the pipeline.
# TYPE otelcol_processor_refused_metric_points counter
otelcol_processor_refused_metric_points{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_refused_spans Number of spans that were rejected by the next component in the pipeline.
# TYPE otelcol_processor_refused_spans counter
otelcol_processor_refused_spans{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_tail_sampling_count_traces_sampled Count of traces that were sampled or not per sampling policy
# TYPE otelcol_processor_tail_sampling_count_traces_sampled counter
otelcol_processor_tail_sampling_count_traces_sampled{policy="baseline",sampled="false",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_tail_sampling_count_traces_sampled{policy="canary",sampled="true",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_tail_sampling_count_traces_sampled{policy="errors",sampled="false",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_tail_sampling_count_traces_sampled{policy="slow-traces",sampled="false",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_tail_sampling_global_count_traces_sampled Global count of traces that were sampled or not by at least one policy
# TYPE otelcol_processor_tail_sampling_global_count_traces_sampled counter
otelcol_processor_tail_sampling_global_count_traces_sampled{sampled="true",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_tail_sampling_new_trace_id_received Counts the arrival of new traces
# TYPE otelcol_processor_tail_sampling_new_trace_id_received counter
otelcol_processor_tail_sampling_new_trace_id_received{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_tail_sampling_sampling_decision_latency Latency (in microseconds) of a given sampling policy
# TYPE otelcol_processor_tail_sampling_sampling_decision_latency histogram
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="150"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="200"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="300"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="400"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_sum{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
otelcol_processor_tail_sampling_sampling_decision_latency_count{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="150"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="200"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="300"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="400"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_sum{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
otelcol_processor_tail_sampling_sampling_decision_latency_count{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="150"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="200"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="300"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="400"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_sum{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
otelcol_processor_tail_sampling_sampling_decision_latency_count{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="150"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="200"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="300"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="400"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_sum{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
otelcol_processor_tail_sampling_sampling_decision_latency_count{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_tail_sampling_sampling_decision_timer_latency Latency (in microseconds) of each run of the sampling decision timer
# TYPE otelcol_processor_tail_sampling_sampling_decision_timer_latency histogram
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="150"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="200"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="300"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="400"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_sum{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 1008
otelcol_processor_tail_sampling_sampling_decision_timer_latency_count{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_tail_sampling_sampling_policy_evaluation_error Count of sampling policy evaluation errors
# TYPE otelcol_processor_tail_sampling_sampling_policy_evaluation_error counter
otelcol_processor_tail_sampling_sampling_policy_evaluation_error{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_tail_sampling_sampling_trace_dropped_too_early Count of traces that needed to be dropped before the configured wait time
# TYPE otelcol_processor_tail_sampling_sampling_trace_dropped_too_early counter
otelcol_processor_tail_sampling_sampling_trace_dropped_too_early{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_tail_sampling_sampling_traces_on_memory Tracks the number of traces current on memory
# TYPE otelcol_processor_tail_sampling_sampling_traces_on_memory gauge
otelcol_processor_tail_sampling_sampling_traces_on_memory{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 2
# HELP otelcol_receiver_accepted_log_records Number of log records successfully pushed into the pipeline.
# TYPE otelcol_receiver_accepted_log_records counter
otelcol_receiver_accepted_log_records{receiver="filelog",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport=""} 182
otelcol_receiver_accepted_log_records{receiver="otlp",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport="http"} 48
otelcol_receiver_accepted_log_records{receiver="windowseventlog/application",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport=""} 4852
otelcol_receiver_accepted_log_records{receiver="windowseventlog/system",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport=""} 26
# HELP otelcol_receiver_accepted_metric_points Number of metric points successfully pushed into the pipeline.
# TYPE otelcol_receiver_accepted_metric_points counter
otelcol_receiver_accepted_metric_points{receiver="otlp",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport="http"} 2
# HELP otelcol_receiver_accepted_spans Number of spans successfully pushed into the pipeline.
# TYPE otelcol_receiver_accepted_spans counter
otelcol_receiver_accepted_spans{receiver="otlp",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport="http"} 2
# HELP otelcol_receiver_refused_log_records Number of log records that could not be pushed into the pipeline.
# TYPE otelcol_receiver_refused_log_records counter
otelcol_receiver_refused_log_records{receiver="filelog",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport=""} 0
otelcol_receiver_refused_log_records{receiver="otlp",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport="http"} 0
otelcol_receiver_refused_log_records{receiver="windowseventlog/application",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport=""} 0
otelcol_receiver_refused_log_records{receiver="windowseventlog/system",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport=""} 0
# HELP otelcol_receiver_refused_metric_points Number of metric points that could not be pushed into the pipeline.
# TYPE otelcol_receiver_refused_metric_points counter
otelcol_receiver_refused_metric_points{receiver="otlp",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport="http"} 0
# HELP otelcol_receiver_refused_spans Number of spans that could not be pushed into the pipeline.
# TYPE otelcol_receiver_refused_spans counter
otelcol_receiver_refused_spans{receiver="otlp",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport="http"} 0
# HELP target_info Target metadata
# TYPE target_info gauge
target_info{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 1

- **Send Failed**: # HELP otelcol_exporter_queue_capacity Fixed capacity of the retry queue (in batches)
# TYPE otelcol_exporter_queue_capacity gauge
otelcol_exporter_queue_capacity{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 5000
# HELP otelcol_exporter_queue_size Current size of the retry queue (in batches)
# TYPE otelcol_exporter_queue_size gauge
otelcol_exporter_queue_size{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_exporter_send_failed_log_records Number of log records in failed attempts to send to destination.
# TYPE otelcol_exporter_send_failed_log_records counter
otelcol_exporter_send_failed_log_records{exporter="logging",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
otelcol_exporter_send_failed_log_records{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_exporter_send_failed_metric_points Number of metric points in failed attempts to send to destination.
# TYPE otelcol_exporter_send_failed_metric_points counter
otelcol_exporter_send_failed_metric_points{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_exporter_send_failed_spans Number of spans in failed attempts to send to destination.
# TYPE otelcol_exporter_send_failed_spans counter
otelcol_exporter_send_failed_spans{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_exporter_sent_log_records Number of log record successfully sent to destination.
# TYPE otelcol_exporter_sent_log_records counter
otelcol_exporter_sent_log_records{exporter="logging",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 5107
otelcol_exporter_sent_log_records{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 5107
# HELP otelcol_exporter_sent_metric_points Number of metric points successfully sent to destination.
# TYPE otelcol_exporter_sent_metric_points counter
otelcol_exporter_sent_metric_points{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_exporter_sent_spans Number of spans successfully sent to destination.
# TYPE otelcol_exporter_sent_spans counter
otelcol_exporter_sent_spans{exporter="otlp/sigz",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_fileconsumer_open_files Number of open files
# TYPE otelcol_fileconsumer_open_files gauge
otelcol_fileconsumer_open_files{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_fileconsumer_reading_files Number of open files that are being read
# TYPE otelcol_fileconsumer_reading_files gauge
otelcol_fileconsumer_reading_files{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_process_cpu_seconds Total CPU user and system time in seconds
# TYPE otelcol_process_cpu_seconds counter
otelcol_process_cpu_seconds{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 693.421875
# HELP otelcol_process_memory_rss Total physical memory (resident set size)
# TYPE otelcol_process_memory_rss gauge
otelcol_process_memory_rss{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 1.33996544e+08
# HELP otelcol_process_runtime_heap_alloc_bytes Bytes of allocated heap objects (see 'go doc runtime.MemStats.HeapAlloc')
# TYPE otelcol_process_runtime_heap_alloc_bytes gauge
otelcol_process_runtime_heap_alloc_bytes{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 7.144776e+07
# HELP otelcol_process_runtime_total_alloc_bytes Cumulative bytes allocated for heap objects (see 'go doc runtime.MemStats.TotalAlloc')
# TYPE otelcol_process_runtime_total_alloc_bytes counter
otelcol_process_runtime_total_alloc_bytes{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 9.8353111632e+10
# HELP otelcol_process_runtime_total_sys_memory_bytes Total bytes of memory obtained from the OS (see 'go doc runtime.MemStats.Sys')
# TYPE otelcol_process_runtime_total_sys_memory_bytes gauge
otelcol_process_runtime_total_sys_memory_bytes{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 1.2453708e+08
# HELP otelcol_process_uptime Uptime of the process
# TYPE otelcol_process_uptime counter
otelcol_process_uptime{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 15745.5537554
# HELP otelcol_processor_accepted_log_records Number of log records successfully pushed into the next component in the pipeline.
# TYPE otelcol_processor_accepted_log_records counter
otelcol_processor_accepted_log_records{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 5108
# HELP otelcol_processor_accepted_metric_points Number of metric points successfully pushed into the next component in the pipeline.
# TYPE otelcol_processor_accepted_metric_points counter
otelcol_processor_accepted_metric_points{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_accepted_spans Number of spans successfully pushed into the next component in the pipeline.
# TYPE otelcol_processor_accepted_spans counter
otelcol_processor_accepted_spans{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_batch_batch_send_size Number of units in the batch
# TYPE otelcol_processor_batch_batch_send_size histogram
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 4215
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="250"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="6000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="7000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="8000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="9000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100000"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4216
otelcol_processor_batch_batch_send_size_sum{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 5111
otelcol_processor_batch_batch_send_size_count{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4216
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="250"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="6000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="7000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="8000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="9000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100000"} 4
otelcol_processor_batch_batch_send_size_bucket{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4
otelcol_processor_batch_batch_send_size_sum{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_batch_batch_send_size_count{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_batch_metadata_cardinality Number of distinct metadata value combinations being processed
# TYPE otelcol_processor_batch_metadata_cardinality gauge
otelcol_processor_batch_metadata_cardinality{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 1
# HELP otelcol_processor_batch_timeout_trigger_send Number of times the batch was sent due to a timeout trigger
# TYPE otelcol_processor_batch_timeout_trigger_send counter
otelcol_processor_batch_timeout_trigger_send{processor="batch",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4216
otelcol_processor_batch_timeout_trigger_send{processor="batch/iona",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_dropped_log_records Number of log records that were dropped.
# TYPE otelcol_processor_dropped_log_records counter
otelcol_processor_dropped_log_records{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_dropped_metric_points Number of metric points that were dropped.
# TYPE otelcol_processor_dropped_metric_points counter
otelcol_processor_dropped_metric_points{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_dropped_spans Number of spans that were dropped.
# TYPE otelcol_processor_dropped_spans counter
otelcol_processor_dropped_spans{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_filter_logs_filtered Number of logs dropped by the filter processor
# TYPE otelcol_processor_filter_logs_filtered counter
otelcol_processor_filter_logs_filtered{filter="filter/drop_noise",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 1
# HELP otelcol_processor_inserted_log_records Number of log records that were inserted.
# TYPE otelcol_processor_inserted_log_records counter
otelcol_processor_inserted_log_records{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_inserted_metric_points Number of metric points that were inserted.
# TYPE otelcol_processor_inserted_metric_points counter
otelcol_processor_inserted_metric_points{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_inserted_spans Number of spans that were inserted.
# TYPE otelcol_processor_inserted_spans counter
otelcol_processor_inserted_spans{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_refused_log_records Number of log records that were rejected by the next component in the pipeline.
# TYPE otelcol_processor_refused_log_records counter
otelcol_processor_refused_log_records{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_refused_metric_points Number of metric points that were rejected by the next component in the pipeline.
# TYPE otelcol_processor_refused_metric_points counter
otelcol_processor_refused_metric_points{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_refused_spans Number of spans that were rejected by the next component in the pipeline.
# TYPE otelcol_processor_refused_spans counter
otelcol_processor_refused_spans{processor="memory_limiter",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_tail_sampling_count_traces_sampled Count of traces that were sampled or not per sampling policy
# TYPE otelcol_processor_tail_sampling_count_traces_sampled counter
otelcol_processor_tail_sampling_count_traces_sampled{policy="baseline",sampled="false",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_tail_sampling_count_traces_sampled{policy="canary",sampled="true",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_tail_sampling_count_traces_sampled{policy="errors",sampled="false",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_tail_sampling_count_traces_sampled{policy="slow-traces",sampled="false",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_tail_sampling_global_count_traces_sampled Global count of traces that were sampled or not by at least one policy
# TYPE otelcol_processor_tail_sampling_global_count_traces_sampled counter
otelcol_processor_tail_sampling_global_count_traces_sampled{sampled="true",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_tail_sampling_new_trace_id_received Counts the arrival of new traces
# TYPE otelcol_processor_tail_sampling_new_trace_id_received counter
otelcol_processor_tail_sampling_new_trace_id_received{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_tail_sampling_sampling_decision_latency Latency (in microseconds) of a given sampling policy
# TYPE otelcol_processor_tail_sampling_sampling_decision_latency histogram
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="150"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="200"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="300"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="400"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_sum{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
otelcol_processor_tail_sampling_sampling_decision_latency_count{policy="baseline",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="150"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="200"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="300"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="400"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_sum{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
otelcol_processor_tail_sampling_sampling_decision_latency_count{policy="canary",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="150"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="200"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="300"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="400"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_sum{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
otelcol_processor_tail_sampling_sampling_decision_latency_count{policy="errors",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="150"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="200"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="300"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="400"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_bucket{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4
otelcol_processor_tail_sampling_sampling_decision_latency_sum{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
otelcol_processor_tail_sampling_sampling_decision_latency_count{policy="slow-traces",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_tail_sampling_sampling_decision_timer_latency Latency (in microseconds) of each run of the sampling decision timer
# TYPE otelcol_processor_tail_sampling_sampling_decision_timer_latency histogram
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="25"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="75"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="100"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="150"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="200"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="300"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="400"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="500"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="750"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="1000"} 3
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="2000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="3000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="4000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="5000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="10000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="20000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="30000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="50000"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_bucket{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",le="+Inf"} 4
otelcol_processor_tail_sampling_sampling_decision_timer_latency_sum{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 1008
otelcol_processor_tail_sampling_sampling_decision_timer_latency_count{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 4
# HELP otelcol_processor_tail_sampling_sampling_policy_evaluation_error Count of sampling policy evaluation errors
# TYPE otelcol_processor_tail_sampling_sampling_policy_evaluation_error counter
otelcol_processor_tail_sampling_sampling_policy_evaluation_error{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_tail_sampling_sampling_trace_dropped_too_early Count of traces that needed to be dropped before the configured wait time
# TYPE otelcol_processor_tail_sampling_sampling_trace_dropped_too_early counter
otelcol_processor_tail_sampling_sampling_trace_dropped_too_early{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 0
# HELP otelcol_processor_tail_sampling_sampling_traces_on_memory Tracks the number of traces current on memory
# TYPE otelcol_processor_tail_sampling_sampling_traces_on_memory gauge
otelcol_processor_tail_sampling_sampling_traces_on_memory{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 2
# HELP otelcol_receiver_accepted_log_records Number of log records successfully pushed into the pipeline.
# TYPE otelcol_receiver_accepted_log_records counter
otelcol_receiver_accepted_log_records{receiver="filelog",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport=""} 182
otelcol_receiver_accepted_log_records{receiver="otlp",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport="http"} 48
otelcol_receiver_accepted_log_records{receiver="windowseventlog/application",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport=""} 4852
otelcol_receiver_accepted_log_records{receiver="windowseventlog/system",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport=""} 26
# HELP otelcol_receiver_accepted_metric_points Number of metric points successfully pushed into the pipeline.
# TYPE otelcol_receiver_accepted_metric_points counter
otelcol_receiver_accepted_metric_points{receiver="otlp",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport="http"} 2
# HELP otelcol_receiver_accepted_spans Number of spans successfully pushed into the pipeline.
# TYPE otelcol_receiver_accepted_spans counter
otelcol_receiver_accepted_spans{receiver="otlp",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport="http"} 2
# HELP otelcol_receiver_refused_log_records Number of log records that could not be pushed into the pipeline.
# TYPE otelcol_receiver_refused_log_records counter
otelcol_receiver_refused_log_records{receiver="filelog",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport=""} 0
otelcol_receiver_refused_log_records{receiver="otlp",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport="http"} 0
otelcol_receiver_refused_log_records{receiver="windowseventlog/application",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport=""} 0
otelcol_receiver_refused_log_records{receiver="windowseventlog/system",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport=""} 0
# HELP otelcol_receiver_refused_metric_points Number of metric points that could not be pushed into the pipeline.
# TYPE otelcol_receiver_refused_metric_points counter
otelcol_receiver_refused_metric_points{receiver="otlp",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport="http"} 0
# HELP otelcol_receiver_refused_spans Number of spans that could not be pushed into the pipeline.
# TYPE otelcol_receiver_refused_spans counter
otelcol_receiver_refused_spans{receiver="otlp",service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0",transport="http"} 0
# HELP target_info Target metadata
# TYPE target_info gauge
target_info{service_instance_id="2398626b-fe9f-4b0c-a786-21d4285060d5",service_name="otelcol-contrib",service_version="0.104.0"} 1


## Analysis

### Performance Metrics
- **Ingestion Rate**: 0 logs/second
- **Processing Efficiency**: 0%
- **Queue Utilization**: %

### Recommendations
1. **If Success Rate < 95%**: Consider increasing batch timeout or reducing batch size
2. **If Queue Utilization > 80%**: Consider increasing queue capacity or reducing load
3. **If Send Failed > 0**: Check exporter configuration and network connectivity

## Files Generated
- **Results**: $ResultsFile
- **Report**: $ReportFile

## Next Steps
1. Review current performance metrics
2. Consider configuration adjustments based on results
3. Run additional tests with different parameters
4. Set up monitoring for queue pressure and latency

---
*Generated by E2 Ratio Simple Analysis Script*
