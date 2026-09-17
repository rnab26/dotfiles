-- Kit cockpit — ce qu'on n'a compris qu'après avoir perdu des notes deux fois.
--
-- Une note de chantier vit souvent depuis plusieurs sessions : elle porte des mots
-- qu'on n'a écrits nulle part ailleurs. Un simple "relis avant d'écrire" en
-- consigne ne suffit pas, il a été oublié deux jours de suite. D'où un trigger,
-- pas une bonne intention.

create table if not exists dev_items_historique (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null, -- pas de FK cascade : voir dev_items_supprimes plus bas pour pourquoi
  champ text not null,
  ancienne_valeur text,
  nouvelle_valeur text,
  changed_at timestamptz not null default now()
);

create index if not exists dev_items_historique_item_idx on dev_items_historique (item_id, changed_at desc);

create or replace function tracer_changement_dev_item()
returns trigger
language plpgsql
as $$
begin
  -- Seuls les champs qui comptent pour un humain qui relit l'historique.
  -- `claimed_by`/`claim_expires_at` tournent en continu (une passe par heure) :
  -- les tracer noierait en un jour les changements qui comptent vraiment.
  if new.title is distinct from old.title then
    insert into dev_items_historique (item_id, champ, ancienne_valeur, nouvelle_valeur)
    values (old.id, 'title', old.title, new.title);
  end if;
  if new.notes is distinct from old.notes then
    insert into dev_items_historique (item_id, champ, ancienne_valeur, nouvelle_valeur)
    values (old.id, 'notes', old.notes, new.notes);
  end if;
  if new.status is distinct from old.status then
    insert into dev_items_historique (item_id, champ, ancienne_valeur, nouvelle_valeur)
    values (old.id, 'status', old.status, new.status);
  end if;
  if new.priority is distinct from old.priority then
    insert into dev_items_historique (item_id, champ, ancienne_valeur, nouvelle_valeur)
    values (old.id, 'priority', old.priority, new.priority);
  end if;
  if new.theme is distinct from old.theme then
    insert into dev_items_historique (item_id, champ, ancienne_valeur, nouvelle_valeur)
    values (old.id, 'theme', old.theme, new.theme);
  end if;
  if new.archived_at is distinct from old.archived_at then
    insert into dev_items_historique (item_id, champ, ancienne_valeur, nouvelle_valeur)
    values (old.id, 'archived_at', old.archived_at::text, new.archived_at::text);
  end if;
  return new;
end;
$$;

drop trigger if exists dev_items_historique_trigger on dev_items;
create trigger dev_items_historique_trigger
  before update on dev_items
  for each row
  execute function tracer_changement_dev_item();

-- Rendre l'ancienne note, en traçant la restauration elle-même (sinon on remplace
-- une perte par une autre : plus aucune trace de ce qui s'est passé).
create or replace function restaurer_note_item(p_id uuid)
returns text
language plpgsql
as $$
declare
  v_ancienne text;
begin
  select ancienne_valeur into v_ancienne
  from dev_items_historique
  where item_id = p_id and champ = 'notes'
  order by changed_at desc
  limit 1;

  if v_ancienne is null then
    raise exception 'Aucune note antérieure trouvée pour %', p_id;
  end if;

  update dev_items set notes = v_ancienne where id = p_id;
  return v_ancienne;
end;
$$;

-- Une SUPPRESSION ne laissait aucune trace : un vrai DELETE fait disparaître le
-- chantier sans une ligne de log, et une table de trace ordinaire (avec FK cascade
-- vers dev_items) serait emportée par ce même DELETE — exactement le trou qu'on
-- rebouche. `dev_items_supprimes` n'a AUCUN lien de cascade : elle survit à la
-- suppression qu'elle décrit.
create table if not exists dev_items_supprimes (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null,
  user_id uuid,
  title text,
  notes text,
  status text,
  priority text,
  theme text,
  created_at timestamptz,
  deleted_at timestamptz not null default now()
);

create or replace function tracer_suppression_dev_item()
returns trigger
language plpgsql
as $$
begin
  insert into dev_items_supprimes (item_id, user_id, title, notes, status, priority, theme, created_at)
  values (old.id, old.user_id, old.title, old.notes, old.status, old.priority, old.theme, old.created_at);
  return old;
end;
$$;

drop trigger if exists dev_items_suppression_trigger on dev_items;
create trigger dev_items_suppression_trigger
  before delete on dev_items
  for each row
  execute function tracer_suppression_dev_item();

-- La restauration efface la trace : on ne veut pas pouvoir recréer le même
-- chantier deux fois par erreur.
create or replace function restaurer_item_supprime(p_id uuid)
returns uuid
language plpgsql
as $$
declare
  v_row dev_items_supprimes%rowtype;
  v_new_id uuid;
begin
  select * into v_row from dev_items_supprimes where item_id = p_id order by deleted_at desc limit 1;
  if not found then
    raise exception 'Aucune suppression tracée pour %', p_id;
  end if;

  insert into dev_items (user_id, title, notes, status, priority, theme, created_at)
  values (v_row.user_id, v_row.title, v_row.notes, v_row.status, v_row.priority, v_row.theme, v_row.created_at)
  returning id into v_new_id;

  delete from dev_items_supprimes where id = v_row.id;
  return v_new_id;
end;
$$;
