content = File.read('app/views/prop_firm_accounts/new.html.erb')

# Strip the inline <script> block completely
content.sub!(/<!-- SCRIPT DE LÓGICA MULTI-STEP -->\s*<script>.*?<\/script>/m, "")

# Add data-controller to the main form
content.sub!(/(<form.*?id="onboarding-wizard-form".*?>)/, '\1' + "\n" + '    <div data-controller="prop-wizard">')
# Close the div at the end before end
content.sub!(/(\s*)<% end %>$/, '\1  </div>\1<% end %>')

# Since our controller will bind globally to window exactly as we proved it works,
# but we run it inside connect() so it only executes when stimulus is active.
# This avoids rewriting 50 data-actions.

File.write('app/views/prop_firm_accounts/new.html.erb', content)
