Rails.application.routes.draw do
  get 'upload', to: 'spreadsheet#upload'
end
