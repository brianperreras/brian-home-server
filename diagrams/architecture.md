# Architecture Diagrams

## Storage

```mermaid
flowchart TD
    USB[Unraid USB boot] --> RAM[Unraid loaded into RAM]
    NVME[GM7000 SSD pool] --> APP[Docker appdata and databases]
    HDD[IronWolf 6 TB] --> DATA[Photos documents and media]
    DATA -->|Weekly snapshot| BK[Backup HDD]
    APP -->|Weekly appdata and DB dumps| BK
```

## Services

```mermaid
flowchart LR
    PHONE[Phone] --> IMMICH[Immich]
    BROWSER[Browser] --> IMMICH
    BROWSER --> HA[Home Assistant]
    IMMICH --> PG[PostgreSQL on GM7000]
    IMMICH --> LIB[Photo library on IronWolf]
    HA --> CFG[HA config on GM7000]
    REMOTE[Remote device] --> TS[Tailscale]
    TS --> IMMICH
    TS --> HA
    TS --> UNRAID[Unraid UI]
```
