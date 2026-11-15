-- Execute no SQL Editor do Supabase. Fuso do estabelecimento: America/Sao_Paulo.
create table if not exists public.bookings (
 id uuid primary key default gen_random_uuid(),
 service_id text not null check (service_id in ('manicure','pedicure','combo','gel','alongamento')),
 client_name text not null check (char_length(client_name) between 2 and 100),
 client_phone text not null check (client_phone ~ '^[0-9]{10,13}$'),
 notes text not null default '',
 starts_at timestamp without time zone not null,
 ends_at timestamp without time zone not null,
 created_at timestamptz not null default now(),
 status text not null default 'confirmed' check(status in ('confirmed','cancelled')),
 constraint positive_duration check (ends_at > starts_at)
);
create index if not exists bookings_date_idx on public.bookings(starts_at,status);
alter table public.bookings enable row level security;
-- Nenhuma política pública de leitura/escrita: acesso apenas pelas funções SECURITY DEFINER.
create or replace function public.get_busy_slots(p_date date)
returns table(start_time text, end_time text)
language sql security definer set search_path = public as $$
 select to_char(starts_at,'HH24:MI'),to_char(ends_at,'HH24:MI')
 from public.bookings
 where status='confirmed' and starts_at >= p_date::timestamp and starts_at < (p_date+1)::timestamp;
$$;
create or replace function public.create_booking(p_service_id text,p_date date,p_time text,p_name text,p_phone text,p_notes text default '')
returns uuid language plpgsql security definer set search_path = public as $$
declare v_duration integer; v_start timestamp; v_end timestamp; v_id uuid; v_now timestamp;
begin
 v_duration := case p_service_id when 'manicure' then 45 when 'pedicure' then 60 when 'combo' then 100 when 'gel' then 90 when 'alongamento' then 150 else null end;
 if v_duration is null then raise exception 'Serviço inválido'; end if;
 if p_name is null or char_length(trim(p_name)) not between 2 and 100 then raise exception 'Nome inválido'; end if;
 if p_phone is null or p_phone !~ '^[0-9]{10,13}$' then raise exception 'Telefone inválido'; end if;
 if char_length(coalesce(p_notes,'')) > 400 then raise exception 'Observações muito longas'; end if;
 if p_time !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' then raise exception 'Horário inválido'; end if;
 v_start := p_date::timestamp + p_time::time;
 v_end := v_start + make_interval(mins => v_duration);
 v_now := now() at time zone 'America/Sao_Paulo';
 if v_start <= v_now or v_start > v_now + interval '90 days' then raise exception 'Data fora do período permitido'; end if;
 if extract(dow from p_date)=0 then raise exception 'Não há atendimento aos domingos'; end if;
 if extract(minute from v_start)::integer not in (0,30) then raise exception 'Horário inválido'; end if;
 if v_start::time < time '09:00' or v_end::time > time '18:00' or v_end::date <> p_date then raise exception 'Fora do horário de atendimento'; end if;
 perform pg_advisory_xact_lock(86420, (p_date - date '2000-01-01')::integer);
 if exists(select 1 from public.bookings where status='confirmed' and starts_at < v_end and ends_at > v_start) then raise exception 'Este horário acabou de ser reservado. Escolha outro.'; end if;
 insert into public.bookings(service_id,client_name,client_phone,notes,starts_at,ends_at)
 values(p_service_id,trim(p_name),p_phone,coalesce(p_notes,''),v_start,v_end) returning id into v_id;
 return v_id;
end; $$;
revoke all on public.bookings from anon, authenticated;
revoke all on function public.create_booking(text,date,text,text,text,text) from public;
revoke all on function public.get_busy_slots(date) from public;
grant execute on function public.create_booking(text,date,text,text,text,text) to anon,authenticated;
grant execute on function public.get_busy_slots(date) to anon,authenticated;
-- Produção: adicione CAPTCHA, rate limiting e proteção contra reservas falsas no backend.
