-- Kit cockpit — base : chantiers (dev_items) + journal de bord (dev_log).
-- Générique, ne dépend d'aucune fonctionnalité métier du projet qui l'installe.

create table if not exists dev_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  title text not null,
  notes text,
  status text not null default 'todo' check (status in ('todo', 'in_progress', 'done')),
  priority text not null default 'normal' check (priority in ('low', 'normal', 'high')),
  theme text,
  -- Réservation : quelle session travaille dessus, et jusqu'à quand la réservation vaut.
  -- `claimed_by` porte le nom de branche de la session, pas un identifiant technique :
  -- c'est ce qui s'affiche à l'humain dans le cockpit ("Prise par ...").
  claimed_by text,
  claim_expires_at timestamptz,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists dev_items_status_idx on dev_items (status) where archived_at is null;
create index if not exists dev_items_theme_idx on dev_items (theme) where archived_at is null;

create table if not exists dev_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  item_id uuid references dev_items (id) on delete set null,
  author text not null,
  -- 'question'/'action' : ce qui attend une décision ou un geste humain.
  -- 'reponse' : la réponse humaine à l'une des deux.
  -- 'info'/'blocage' : ce que les sessions se disent, entre elles ou pour information.
  kind text not null check (kind in ('question', 'reponse', 'info', 'blocage', 'action')),
  body text not null,
  -- OBLIGATOIRE pour 'question' et 'action' posées par une session : voir la leçon
  -- "kind='action' porte deux sens opposés" plus bas dans le kit. Sans lui, impossible
  -- de distinguer une vraie demande d'un compte rendu de session, qui utilisent le même kind.
  pourquoi text,
  options jsonb,
  answered_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists dev_log_item_idx on dev_log (item_id);
create index if not exists dev_log_created_idx on dev_log (created_at desc);

-- Réservation atomique : deux sessions qui appellent en même temps, une seule reçoit `true`.
create or replace function claim_dev_item(p_id uuid, p_by text, p_minutes int default 120)
returns boolean
language plpgsql
as $$
declare
  v_ok boolean;
begin
  update dev_items
  set claimed_by = p_by,
      claim_expires_at = now() + (p_minutes || ' minutes')::interval
  where id = p_id
    and archived_at is null
    and (claimed_by is null or claim_expires_at < now() or claimed_by = p_by)
  returning true into v_ok;

  return coalesce(v_ok, false);
end;
$$;

create or replace function release_dev_item(p_id uuid, p_by text)
returns boolean
language plpgsql
as $$
declare
  v_ok boolean;
begin
  update dev_items
  set claimed_by = null, claim_expires_at = null
  where id = p_id and claimed_by = p_by
  returning true into v_ok;

  return coalesce(v_ok, false);
end;
$$;

-- RLS minimale : chacun voit et modifie ses propres chantiers. Adapte selon que ton
-- projet est mono-utilisateur (toi + tes sessions) ou multi-utilisateur.
alter table dev_items enable row level security;
alter table dev_log enable row level security;

create policy dev_items_select_own on dev_items for select using (user_id = auth.uid());
create policy dev_items_insert_own on dev_items for insert with check (user_id = auth.uid());
create policy dev_items_update_own on dev_items for update using (user_id = auth.uid());
create policy dev_items_delete_own on dev_items for delete using (user_id = auth.uid());

create policy dev_log_select_own on dev_log for select using (user_id = auth.uid());
create policy dev_log_insert_own on dev_log for insert with check (user_id = auth.uid());
create policy dev_log_update_own on dev_log for update using (user_id = auth.uid());
