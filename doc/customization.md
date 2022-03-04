# Front end customization

Do you want to customize your instance ? Here is a step by step guide :

# step 1. understand

for your information, you can overide any view in our app by replicating the view structure from `app/views` to `app/views/custom`.

# step 2. just do it :-)

So let's imagine you want to customize the `app/views/root/_footer.html.haml`. Here is a step by step guide:

`$ mkdir app/views/custom/root`
`$ cp app/views/root/_footer.html.haml app/views/custom/root`

and Voila ! you can edit your own template. No need for env var, no worries with conflict etc...
