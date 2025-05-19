%% for TC only, feel free to copy the code, but remember to change it to your own email!!!

function noteMeYJ(message)

mail = 'yanyuj@princeton.edu';
% name = 'xulab2drobot@gmail.com';
name = 'wulab2D@gmail.com';
password = 'puwulab2D!';

setpref('Internet','SMTP_Server','smtp.gmail.com');
setpref('Internet','E_mail',mail);
setpref('Internet','SMTP_Username',name);
setpref('Internet','SMTP_Password',password);
props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','465');
sendmail(mail,message);

end