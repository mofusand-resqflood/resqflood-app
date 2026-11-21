-- Live updates for the resident screens (ETA, announcements, road reports).
do $$
declare
  t text;
begin
  foreach t in array array['requests', 'announcements', 'blocked_roads', 'shelters']
  loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- Flood-depth photos and road-report photos.
insert into storage.buckets (id, name, public)
values ('incident-photos', 'incident-photos', false)
on conflict (id) do nothing;

drop policy if exists "resident uploads own incident photo" on storage.objects;
drop policy if exists "resident reads own incident photo" on storage.objects;

create policy "resident uploads own incident photo"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'incident-photos'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "resident reads own incident photo"
on storage.objects for select to authenticated
using (
  bucket_id = 'incident-photos'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);