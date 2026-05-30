-- Supabase Storage policies for EcoByte uploads
-- Apply this in the Supabase SQL editor or via Supabase migrations.

drop policy if exists "uploads bucket public read" on storage.objects;
drop policy if exists "authenticated users can upload to uploads bucket" on storage.objects;
drop policy if exists "authenticated users can update own uploads" on storage.objects;
drop policy if exists "authenticated users can delete own uploads" on storage.objects;

create policy "uploads bucket public read"
on storage.objects
for select
to public
using (bucket_id = 'uploads');

create policy "authenticated users can upload to uploads bucket"
on storage.objects
for insert
to authenticated
with check (bucket_id = 'uploads' and auth.role() = 'authenticated');

create policy "authenticated users can update own uploads"
on storage.objects
for update
to authenticated
using (bucket_id = 'uploads' and owner = auth.uid() and auth.role() = 'authenticated')
with check (bucket_id = 'uploads' and owner = auth.uid() and auth.role() = 'authenticated');

create policy "authenticated users can delete own uploads"
on storage.objects
for delete
to authenticated
using (bucket_id = 'uploads' and owner = auth.uid() and auth.role() = 'authenticated');
