package metrics

import (
	"time"

	"github.com/shirou/gopsutil/v4/cpu"
	"github.com/shirou/gopsutil/v4/disk"
	"github.com/shirou/gopsutil/v4/host"
	"github.com/shirou/gopsutil/v4/load"
	"github.com/shirou/gopsutil/v4/mem"
	"github.com/shirou/gopsutil/v4/net"
)

// SystemInfo holds basic system information
type SystemInfo struct {
	Hostname        string `json:"hostname"`
	Platform        string `json:"platform"`
	PlatformVersion string `json:"platform_version"`
	Architecture    string `json:"architecture"`
	Uptime          uint64 `json:"uptime"` // seconds
	BootTime        uint64 `json:"boot_time"`
	KernelVersion   string `json:"kernel_version"`
}

// CPUMetrics holds CPU usage data
type CPUMetrics struct {
	UsagePercent float64 `json:"usage_percent"` // overall CPU usage
	CoreCount    int     `json:"core_count"`
	Load1        float64 `json:"load_1"`  // 1-minute load average
	Load5        float64 `json:"load_5"`  // 5-minute load average
	Load15       float64 `json:"load_15"` // 15-minute load average
}

// MemoryMetrics holds memory usage data
type MemoryMetrics struct {
	Total       uint64  `json:"total"`
	Used        uint64  `json:"used"`
	Available   uint64  `json:"available"`
	UsedPercent float64 `json:"used_percent"`
	SwapTotal   uint64  `json:"swap_total"`
	SwapUsed    uint64  `json:"swap_used"`
}

// DiskPartition holds info about a single disk partition
type DiskPartition struct {
	Device      string  `json:"device"`
	Mountpoint  string  `json:"mountpoint"`
	Fstype      string  `json:"fstype"`
	Total       uint64  `json:"total"`
	Used        uint64  `json:"used"`
	Free        uint64  `json:"free"`
	UsedPercent float64 `json:"used_percent"`
}

// DiskMetrics holds all disk partition data
type DiskMetrics struct {
	Partitions []DiskPartition `json:"partitions"`
}

// NetworkInterface holds per-interface network stats
type NetworkInterface struct {
	Name        string `json:"name"`
	BytesSent   uint64 `json:"bytes_sent"`
	BytesRecv   uint64 `json:"bytes_recv"`
	PacketsSent uint64 `json:"packets_sent"`
	PacketsRecv uint64 `json:"packets_recv"`
}

// NetworkMetrics holds network I/O data
type NetworkMetrics struct {
	Interfaces []NetworkInterface `json:"interfaces"`
}

// AllMetrics is the top-level response structure
type AllMetrics struct {
	Timestamp int64          `json:"timestamp"`
	System    SystemInfo     `json:"system"`
	CPU       CPUMetrics     `json:"cpu"`
	Memory    MemoryMetrics  `json:"memory"`
	Disk      DiskMetrics    `json:"disk"`
	Network   NetworkMetrics `json:"network"`
}

// Collect gathers all system metrics and returns them
func Collect() (*AllMetrics, error) {
	m := &AllMetrics{
		Timestamp: time.Now().Unix(),
	}

	// System info
	if hi, err := host.Info(); err == nil {
		m.System = SystemInfo{
			Hostname:        hi.Hostname,
			Platform:        hi.Platform,
			PlatformVersion: hi.PlatformVersion,
			Architecture:    hi.KernelArch,
			Uptime:          hi.Uptime,
			BootTime:        hi.BootTime,
			KernelVersion:   hi.KernelVersion,
		}
	}

	// CPU
	if percents, err := cpu.Percent(time.Second, false); err == nil && len(percents) > 0 {
		m.CPU.UsagePercent = percents[0]
	}
	if counts, err := cpu.Counts(true); err == nil {
		m.CPU.CoreCount = counts
	}
	if avg, err := load.Avg(); err == nil {
		m.CPU.Load1 = avg.Load1
		m.CPU.Load5 = avg.Load5
		m.CPU.Load15 = avg.Load15
	}

	// Memory
	if vm, err := mem.VirtualMemory(); err == nil {
		m.Memory.Total = vm.Total
		m.Memory.Used = vm.Used
		m.Memory.Available = vm.Available
		m.Memory.UsedPercent = vm.UsedPercent
	}
	if sm, err := mem.SwapMemory(); err == nil {
		m.Memory.SwapTotal = sm.Total
		m.Memory.SwapUsed = sm.Used
	}

	// Disk
	if parts, err := disk.Partitions(false); err == nil {
		for _, p := range parts {
			if usage, err := disk.Usage(p.Mountpoint); err == nil {
				m.Disk.Partitions = append(m.Disk.Partitions, DiskPartition{
					Device:      p.Device,
					Mountpoint:  p.Mountpoint,
					Fstype:      p.Fstype,
					Total:       usage.Total,
					Used:        usage.Used,
					Free:        usage.Free,
					UsedPercent: usage.UsedPercent,
				})
			}
		}
	}

	// Network
	if counters, err := net.IOCounters(true); err == nil {
		for _, c := range counters {
			m.Network.Interfaces = append(m.Network.Interfaces, NetworkInterface{
				Name:        c.Name,
				BytesSent:   c.BytesSent,
				BytesRecv:   c.BytesRecv,
				PacketsSent: c.PacketsSent,
				PacketsRecv: c.PacketsRecv,
			})
		}
	}

	return m, nil
}
