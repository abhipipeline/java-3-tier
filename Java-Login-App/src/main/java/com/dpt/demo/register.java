package com.dpt.demo;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.servlet.ModelAndView;

@Controller
public class register {
	

	@Value("${spring.datasource.url}")
	private String url;

	@Value("${spring.datasource.username}")
	private String DBusername;

	@Value("${spring.datasource.password}")
	private String DBpassword;
	private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
	
	
	@RequestMapping(value = "register", method = RequestMethod.GET)
	public ModelAndView registerform()
	{
		ModelAndView mv=new ModelAndView("register");
		
		return mv;		
	}
	
	
	@RequestMapping(value = "register", method = RequestMethod.POST)
	public ModelAndView register(String firstName,String lastName,String email,String userName,String password) throws ClassNotFoundException
	{
		Class.forName("com.mysql.cj.jdbc.Driver");
		ModelAndView mv = new ModelAndView("register");
		try (Connection con = DriverManager.getConnection(url, DBusername, DBpassword);
				PreparedStatement st = con.prepareStatement(
						"insert into Employee (first_name,last_name,email,username,password,regdate) values(?,?,?,?,?,CURDATE())")) {

			st.setString(1, firstName);
			st.setString(2, lastName);
			st.setString(3, email);
			st.setString(4, userName);
			st.setString(5, passwordEncoder.encode(password));
			st.executeUpdate();
			mv.addObject("message", "user account has been added for " + userName);

		} catch (SQLException ex) {
			mv.addObject("errorMessage", "Unable to create the user account.");
		}
				
		return mv;		
	}
	

}
