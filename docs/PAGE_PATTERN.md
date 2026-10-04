Page pattern for every index/show/new view (keep it consistent):

<% content_for :title, "Registrations" %>
<section class="mb-12 flex flex-col gap-6 md:flex-row md:items-end md:justify-between">
  <div>
    <p class="eyebrow">Registrations</p>
    <h1 class="display mt-3">Vehicle registrations</h1>
    <p class="lede mt-4">One-sentence description.</p>
  </div>
  <div class="flex gap-3"><%= link_to "New registration", new_registration_path, class: "btn-primary" %></div>
</section>

Filters: a row of .select/.input with a .btn-secondary "Apply" inside a <form> above the table.
Tables: <div class="card overflow-x-auto"><table class="table">...</table></div>; money columns use class "num".
Status badges: positive/final states -> badge-accent; in-progress -> badge-muted; draft/neutral -> badge-outline;
rejected/expired/voided -> badge-danger. Put this mapping in a `status_badge(status)` helper.
Show pages: header section as above, then <div class="card"><div class="card-body"><dl class="dl-grid">...</dl></div></div>,
then related tables, each preceded by <p class="eyebrow mb-4 mt-12">Section name</p>.
Forms: <div class="card"><div class="card-body"> grid of fields (md:grid-cols-2 gap-6), .label + .input/.select,
errors in .field-error, submit .btn-primary, cancel .btn-secondary.
Empty states: <p class="muted py-10 text-center text-sm">No records.</p> inside the card.
