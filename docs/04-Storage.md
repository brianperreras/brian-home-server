# 04 - Storage Layout

Do this chapter **before** Docker and before any app (Immich, Home Assistant, Jellyfin).

Goal: assign disks, create empty shares, start the array. Do **not** install apps here.

## Devices

| Device | Role | Availability |
|---|---|---|
| Acer Predator GM7000 1 TB | SSD pool (`fast` or `cache`) for appdata and databases | 24/7 |
| Seagate IronWolf 6 TB | Array disk 1 (no parity) for photos, documents, media | 24/7 |
| Seagate Exos 6 TB | Unassigned Devices backup disk (add when ready) | Weekly only |

No parity disk. You accept about one week of risk on new data in exchange for a separate backup copy.

## Step 1 — Create the SSD pool

1. In Unraid Main, add the GM7000 as a pool named `fast` or `cache`.
2. Use a simple filesystem for a single drive (XFS is fine).
3. Start the array when disks are assigned (after Step 2 as well).

## Step 2 — Assign the IronWolf

1. Assign IronWolf as **Disk 1**.
2. Leave **Parity** empty.
3. Start the array and format if Unraid asks.
4. Prefer XFS on the IronWolf unless you have a specific reason otherwise.

## Step 3 — Create shares (folders only)

Create these shares now. Leave them empty. Apps will use them later.

### On the SSD pool (primary = pool, secondary = none)

| Share | Purpose |
|---|---|
| `appdata` | Docker configs and databases |
| `system` | Docker system data |
| `domains` | Future VMs (optional) |
| `database-backups-staging` | Temporary DB dumps before weekly backup |

If Unraid offers exclusive/pool-only access for `appdata` and `system`, enable it so they stay on the SSD.

### On the IronWolf (primary = array / Disk 1)

| Share | Purpose |
|---|---|
| `photos` | Immich library later |
| `documents` | Personal files |
| `media` | Jellyfin libraries later |
| `backups-incoming` | PC backups |
| `public` | Optional transfer folder |

For `photos` and `media`, do **not** set cache so large files land on the SSD.

You should now see paths like:

- `/mnt/user/appdata`
- `/mnt/user/photos`
- `/mnt/user/media`

## Step 4 — Exos backup disk (can wait)

When the Exos arrives:

1. Install the Unassigned Devices plugin if not already installed.
2. Attach the Exos; do **not** add it to the array.
3. Format/mount only when needed for backup.
4. Suggested mount point: `/mnt/disks/weekly_backup`
5. Prefer **not** auto-mounting at boot.

Full weekly backup steps are in chapter `10` after apps exist.

## Step 5 — Share security (basic)

- Set private shares to Secure or Private.
- Do not use `root` for SMB day-to-day access.
- Named SMB users can wait until chapter `15`.

## Step 6 — SMART schedule

IronWolf:

- Short test weekly.
- Extended test monthly.
- Temperature warning around 45-48 C; critical around 50-55 C.

Exos (when in use):

- Short test around weekly backup.
- Extended test monthly during a maintenance window.

Watch reallocated, pending, and uncorrectable sectors. UDMA CRC errors often mean a cable issue.

## Done checklist

- [ ] GM7000 pool online
- [ ] IronWolf is Disk 1, parity empty
- [ ] Array started
- [ ] `appdata`, `photos`, `media`, and other shares exist
- [ ] No apps installed yet

**Next:** chapter `05` Docker (enable the engine only).
