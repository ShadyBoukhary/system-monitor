#!/bin/bash

# ZFS metrics collector for Prometheus node_exporter textfile collector
# This script collects ZFS pool status and writes to a file that node_exporter can read

TEXTFILE_DIR="/home/weaver/apps/monitor/node_exporter_textfiles"
OUTPUT_FILE="$TEXTFILE_DIR/zfs.prom"
TEMP_FILE="$OUTPUT_FILE.tmp"

# Create the textfile directory if it doesn't exist
mkdir -p "$TEXTFILE_DIR"

# Function to write help and type for metrics
write_metric_info() {
    local metric_name="$1"
    local help_text="$2"
    local metric_type="$3"
    
    echo "# HELP $metric_name $help_text" >> "$TEMP_FILE"
    echo "# TYPE $metric_name $metric_type" >> "$TEMP_FILE"
}

# Start with empty temp file
> "$TEMP_FILE"

# Check if ZFS is available
if ! command -v zpool &> /dev/null; then
    echo "# ZFS not available" >> "$TEMP_FILE"
    mv "$TEMP_FILE" "$OUTPUT_FILE"
    exit 0
fi

# Get ZFS pool status
write_metric_info "zfs_pool_health" "ZFS pool health status (0=ONLINE, 1=DEGRADED, 2=FAULTED)" "gauge"

# Get the main pool status from zpool status
zpool status | awk '
/^[[:space:]]*pool:/ { pool = $2 }
/^[[:space:]]*state:/ { 
    state = $2
    if (state == "ONLINE") health = 0
    else if (state == "DEGRADED") health = 1
    else if (state == "FAULTED" || state == "OFFLINE") health = 2
    else health = 3
    print "zfs_pool_health{pool=\"" pool "\"} " health
}' >> "$TEMP_FILE"

# Get ZFS pool space usage
write_metric_info "zfs_pool_size_bytes" "ZFS pool total size in bytes" "gauge"
write_metric_info "zfs_pool_allocated_bytes" "ZFS pool allocated space in bytes" "gauge"
write_metric_info "zfs_pool_free_bytes" "ZFS pool free space in bytes" "gauge"

zpool list -Hp | while IFS=$'\t' read name size alloc free ckpoint expandsz frag cap dedup health altroot; do
    if [[ "$name" != "NAME" ]]; then
        echo "zfs_pool_size_bytes{pool=\"$name\"} $size" >> "$TEMP_FILE"
        echo "zfs_pool_allocated_bytes{pool=\"$name\"} $alloc" >> "$TEMP_FILE"
        echo "zfs_pool_free_bytes{pool=\"$name\"} $free" >> "$TEMP_FILE"
    fi
done

# Get ZFS ARC stats if available
if [[ -f /proc/spl/kmod/zfs/arcstats ]]; then
    write_metric_info "zfs_arc_hits_total" "ZFS ARC hits total" "counter"
    write_metric_info "zfs_arc_misses_total" "ZFS ARC misses total" "counter"
    write_metric_info "zfs_arc_size_bytes" "ZFS ARC current size in bytes" "gauge"
    write_metric_info "zfs_arc_c_max_bytes" "ZFS ARC maximum size in bytes" "gauge"
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^([a-zA-Z_]+)[[:space:]]+[0-9]+[[:space:]]+([0-9]+) ]]; then
            metric="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            
            case "$metric" in
                "hits")
                    echo "zfs_arc_hits_total $value" >> "$TEMP_FILE"
                    ;;
                "misses")
                    echo "zfs_arc_misses_total $value" >> "$TEMP_FILE"
                    ;;
                "size")
                    echo "zfs_arc_size_bytes $value" >> "$TEMP_FILE"
                    ;;
                "c_max")
                    echo "zfs_arc_c_max_bytes $value" >> "$TEMP_FILE"
                    ;;
            esac
        fi
    done < /proc/spl/kmod/zfs/arcstats
fi

# Move temp file to final location atomically
mv "$TEMP_FILE" "$OUTPUT_FILE"

echo "ZFS metrics collected at $(date)"
